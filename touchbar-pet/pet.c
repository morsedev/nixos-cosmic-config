/*
 * touchbar-pet.c — gato que "teclea" en la Touch Bar + reloj.
 *
 * Modos:
 *   --render out.ppm   dibuja un fotograma a un PPM (para revisar el diseño)
 *   --run              dibuja en el panel (DRM) y anima con el teclado
 *
 * El panel se maneja como un buffer vertical de 64x2008 que hay que rotar al
 * volcar los píxeles (igual que hace tiny-dfr).
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <errno.h>
#include <fcntl.h>
#include <dirent.h>
#include <poll.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <sys/mman.h>

#include <xf86drm.h>
#include <xf86drmMode.h>

#define W 2048
#define H 60

static uint32_t canvas[W * H];

/* --- paleta Tokyo Night --- */
#define BG        0x16161e
#define SURFACE   0x1f2335
#define BORDER    0x292e42
#define FG        0xc0caf5
#define FUR       0xc9cbe8
#define DIM       0x565f89
#define BLUE      0x7aa2f7
#define CYAN      0x7dcfff
#define PURPLE    0xbb9af7
#define PINK      0xf7768e
#define GREEN     0x9ece6a

static void px(int x, int y, uint32_t c) {
    if (x < 0 || y < 0 || x >= W || y >= H) return;
    canvas[y * W + x] = c;
}

static void fill(int x0, int y0, int w, int h, uint32_t c) {
    for (int y = y0; y < y0 + h; y++)
        for (int x = x0; x < x0 + w; x++) px(x, y, c);
}

static void rounded(int x0, int y0, int w, int h, int r, uint32_t c) {
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int dx = 0, dy = 0;
            if (x < r && y < r) { dx = r - x; dy = r - y; }
            else if (x >= w - r && y < r) { dx = x - (w - r - 1); dy = r - y; }
            else if (x < r && y >= h - r) { dx = r - x; dy = y - (h - r - 1); }
            else if (x >= w - r && y >= h - r) { dx = x - (w - r - 1); dy = y - (h - r - 1); }
            if (dx * dx + dy * dy <= r * r) px(x0 + x, y0 + y, c);
        }
    }
}

static void disc(int cx, int cy, int r, uint32_t c) {
    for (int y = -r; y <= r; y++)
        for (int x = -r; x <= r; x++)
            if (x * x + y * y <= r * r) px(cx + x, cy + y, c);
}

/* ------------------------------------------------------------------------- */
/*  Reloj: dígitos de 7 segmentos                                            */
/* ------------------------------------------------------------------------- */
static const uint8_t SEG[10] = {
    0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f
};

static void digit(int x, int y, int w, int h, int th, int d, uint32_t c) {
    if (d == 1) {                       /* el 1 se dibuja centrado: más legible */
        fill(x + w / 2 - th / 2, y, th, h, c);
        return;
    }
    uint8_t s = SEG[d % 10];
    if (s & 0x01) fill(x + th, y, w - 2 * th, th, c);                  /* a */
    if (s & 0x02) fill(x + w - th, y + th, th, h / 2 - th, c);         /* b */
    if (s & 0x04) fill(x + w - th, y + h / 2, th, h / 2 - th, c);      /* c */
    if (s & 0x08) fill(x + th, y + h - th, w - 2 * th, th, c);         /* d */
    if (s & 0x10) fill(x, y + h / 2, th, h / 2 - th, c);               /* e */
    if (s & 0x20) fill(x, y + th, th, h / 2 - th, c);                  /* f */
    if (s & 0x40) fill(x + th, y + h / 2 - th / 2, w - 2 * th, th, c); /* g */
}

static void draw_time(int cx, int cy, int h, int blink) {
    time_t t = time(NULL);
    struct tm tm;
    localtime_r(&t, &tm);

    int w = (int)(h * 0.58);
    int th = h / 10 > 2 ? h / 10 : 2;
    int gap = th + 3;
    int colon = th + 2;
    int total = 4 * w + 3 * gap + colon;

    int x = cx - total / 2;
    int y = cy - h / 2;

    digit(x, y, w, h, th, tm.tm_hour / 10, BLUE); x += w + gap;
    digit(x, y, w, h, th, tm.tm_hour % 10, BLUE); x += w + gap;

    if (blink) {
        int r = th / 2 + 1;
        disc(x + colon / 2, y + h / 3, r, BLUE);
        disc(x + colon / 2, y + 2 * h / 3, r, BLUE);
    }
    x += colon + gap;

    digit(x, y, w, h, th, tm.tm_min / 10, BLUE); x += w + gap;
    digit(x, y, w, h, th, tm.tm_min % 10, BLUE);
}

/* ------------------------------------------------------------------------- */
/*  Gato                                                                     */
/* ------------------------------------------------------------------------- */
static void ear(int x, int base, int w, int h, uint32_t c) {
    for (int i = 0; i < h; i++) {
        int half = (i * w) / (2 * h);
        fill(x - half, base - i, 2 * half + 1, 1, c);
    }
}

static void draw_cat(int cx, int paw, int sway) {
    /* teclado */
    rounded(cx - 78, 44, 156, 12, 3, SURFACE);
    for (int i = 0; i < 12; i++) {
        int under_l = (i >= 2 && i <= 4);
        int under_r = (i >= 7 && i <= 9);
        uint32_t kc = BORDER;
        if ((paw == 0 || paw == 2) && under_l) kc = BLUE;
        if ((paw == 1 || paw == 2) && under_r) kc = BLUE;
        fill(cx - 72 + i * 12, 47, 9, 6, kc);
    }

    /* cola */
    for (int i = 0; i < 20; i++) {
        int x = cx + 28 + i;
        int y = 38 - (i * i) / 40 + (sway ? (i % 3) : 0);
        disc(x, y, i > 14 ? 1 : 2, FUR);
    }

    /* cuerpo */
    rounded(cx - 30, 28, 60, 18, 8, FUR);

    /* patas encima del teclado */
    int pl = (paw == 0 || paw == 2) ? -4 : 0;
    int pr = (paw == 1 || paw == 2) ? -4 : 0;
    rounded(cx - 20, 40 + pl, 12, 7, 3, FUR);
    rounded(cx + 8, 40 + pr, 12, 7, 3, FUR);
    /* deditos */
    fill(cx - 18, 44 + pl, 2, 2, SURFACE);
    fill(cx - 14, 44 + pl, 2, 2, SURFACE);
    fill(cx + 10, 44 + pr, 2, 2, SURFACE);
    fill(cx + 14, 44 + pr, 2, 2, SURFACE);

    /* orejas */
    ear(cx - 8, 14, 11, 8, FUR);
    ear(cx + 8, 14, 11, 8, FUR);
    ear(cx - 8, 14, 6, 4, PINK);
    ear(cx + 8, 14, 6, 4, PINK);

    /* cabeza */
    disc(cx, 22, 14, FUR);

    /* ojos */
    disc(cx - 5, 20, 2, CYAN);
    disc(cx + 5, 20, 2, CYAN);
    px(cx - 5, 20, 0x101018);
    px(cx + 5, 20, 0x101018);

    /* hocico */
    px(cx, 25, PINK);

    /* bigotes */
    for (int i = 0; i < 5; i++) {
        px(cx - 9 - i, 24 + i / 3, DIM);
        px(cx + 9 + i, 24 + i / 3, DIM);
    }
}

/* ------------------------------------------------------------------------- */
/*  Copo de nieve (NixOS), dibujado a mano                                    */
/* ------------------------------------------------------------------------- */
static void snowflake(int cx, int cy, int r, uint32_t c) {
    for (int a = 0; a < 6; a++) {
        double ang = a * 3.14159265 / 3.0;
        double dx = cos(ang), dy = sin(ang);
        for (int d = 0; d <= r; d++) {
            int x = cx + (int)(dx * d), y = cy + (int)(dy * d);
            disc(x, y, 1, c);
        }
        /* ramitas */
        for (int d = r / 2; d <= r; d += 4) {
            int x = cx + (int)(dx * d), y = cy + (int)(dy * d);
            int bx = (int)(-dy * 4), by = (int)(dx * 4);
            disc(x + bx, y + by, 1, c);
            disc(x - bx, y - by, 1, c);
        }
    }
}

/* ------------------------------------------------------------------------- */
static void draw_frame(int paw, int blink, int battery) {
    fill(0, 0, W, H, BG);
    fill(0, 0, W, 1, BORDER);
    fill(0, H - 1, W, 1, BORDER);

    draw_cat(230, paw, blink);

    draw_time(1010, 30, 30, blink);

    snowflake(1700, 30, 15, PURPLE);

    /* batería */
    int bx = W - 86, by = 21;
    rounded(bx, by, 42, 20, 5, DIM);
    fill(bx + 2, by + 2, 38, 16, 0x101018);
    int fillw = (battery * 34) / 100;
    if (fillw > 0) fill(bx + 4, by + 4, fillw, 12, battery > 20 ? GREEN : PINK);
    rounded(bx + 42, by + 6, 4, 8, 1, DIM);
}

/* ------------------------------------------------------------------------- */

/* ------------------------------------------------------------------------- */
/*  Salida DRM (el panel)                                                     */
/* ------------------------------------------------------------------------- */
struct panel {
    int fd;
    uint32_t fb;
    uint32_t handle;
    uint32_t pitch;
    uint32_t height;
    uint8_t *map;
    size_t size;
};

static int add_prop(int fd, drmModeAtomicReq *req, uint32_t obj,
                    uint32_t obj_type, const char *name, uint64_t value) {
    drmModeObjectProperties *props = drmModeObjectGetProperties(fd, obj, obj_type);
    if (!props) return -1;
    int rc = -1;
    for (uint32_t i = 0; i < props->count_props; i++) {
        drmModePropertyRes *pr = drmModeGetProperty(fd, props->props[i]);
        if (!pr) continue;
        if (strcmp(pr->name, name) == 0) {
            rc = drmModeAtomicAddProperty(req, obj, pr->prop_id, value) < 0 ? -1 : 0;
            drmModeFreeProperty(pr);
            break;
        }
        drmModeFreeProperty(pr);
    }
    drmModeFreeObjectProperties(props);
    return rc;
}

/* Abre el panel con un commit ATÓMICO, que es lo único que acepta
   appletbdrm (el mismo camino que usa tiny-dfr). */
static int open_panel(struct panel *p) {
    DIR *d = opendir("/dev/dri");
    if (!d) return -1;
    struct dirent *e;

    while ((e = readdir(d))) {
        if (strncmp(e->d_name, "card", 4) != 0) continue;
        char path[64];
        snprintf(path, sizeof(path), "/dev/dri/%s", e->d_name);

        int fd = open(path, O_RDWR);
        if (fd < 0) continue;

        drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1);
        drmSetClientCap(fd, DRM_CLIENT_CAP_ATOMIC, 1);

        drmModeRes *res = drmModeGetResources(fd);
        if (!res) { close(fd); continue; }

        for (int i = 0; i < res->count_connectors; i++) {
            drmModeConnector *c = drmModeGetConnector(fd, res->connectors[i]);
            if (!c) continue;
            if (c->connection != DRM_MODE_CONNECTED || c->count_modes == 0) {
                drmModeFreeConnector(c);
                continue;
            }
            drmModeModeInfo *m = &c->modes[0];
            if (m->vdisplay / m->hdisplay < 30) {   /* no es la Touch Bar */
                drmModeFreeConnector(c);
                continue;
            }

            uint32_t crtc = 0;
            if (c->encoder_id) {
                drmModeEncoder *enc = drmModeGetEncoder(fd, c->encoder_id);
                if (enc) { crtc = enc->crtc_id; drmModeFreeEncoder(enc); }
            }
            if (!crtc && res->count_crtcs) crtc = res->crtcs[0];

            drmModePlaneRes *pres = drmModeGetPlaneResources(fd);
            if (!pres || pres->count_planes == 0) {
                if (pres) drmModeFreePlaneResources(pres);
                drmModeFreeConnector(c);
                continue;
            }
            uint32_t plane = pres->planes[0];
            drmModeFreePlaneResources(pres);

            if (drmSetMaster(fd) != 0) {
                fprintf(stderr, "%s: no se pudo ser DRM master (%s)\n", path, strerror(errno));
                drmModeFreeConnector(c);
                continue;
            }

            struct drm_mode_create_dumb creq = {0};
            creq.width = 64;
            creq.height = m->vdisplay;
            creq.bpp = 32;
            if (ioctl(fd, DRM_IOCTL_MODE_CREATE_DUMB, &creq) != 0) {
                drmDropMaster(fd); drmModeFreeConnector(c); continue;
            }

            struct drm_mode_map_dumb mreq = {0};
            mreq.handle = creq.handle;
            if (ioctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &mreq) != 0) {
                drmDropMaster(fd); drmModeFreeConnector(c); continue;
            }

            void *map = mmap(NULL, creq.size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, mreq.offset);
            if (map == MAP_FAILED) { drmDropMaster(fd); drmModeFreeConnector(c); continue; }

            uint32_t fb = 0;
            if (drmModeAddFB(fd, creq.width, creq.height, 24, 32, creq.pitch, creq.handle, &fb) != 0) {
                munmap(map, creq.size); drmDropMaster(fd); drmModeFreeConnector(c); continue;
            }

            drmModeAtomicReq *req = drmModeAtomicAlloc();
            uint32_t blob = 0;
            if (drmModeCreatePropertyBlob(fd, m, sizeof(*m), &blob) != 0) blob = 0;

            int ok = 1;
            ok &= (add_prop(fd, req, c->connector_id, DRM_MODE_OBJECT_CONNECTOR, "CRTC_ID", crtc) == 0);
            if (blob)
                ok &= (add_prop(fd, req, crtc, DRM_MODE_OBJECT_CRTC, "MODE_ID", blob) == 0);
            ok &= (add_prop(fd, req, crtc, DRM_MODE_OBJECT_CRTC, "ACTIVE", 1) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "FB_ID", fb) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_ID", crtc) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_X", 0) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_Y", 0) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_W", (uint64_t)m->hdisplay << 16) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_H", (uint64_t)m->vdisplay << 16) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_X", 0) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_Y", 0) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_W", (uint64_t)m->hdisplay) == 0);
            ok &= (add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_H", (uint64_t)m->vdisplay) == 0);

            int rc = -1;
            if (ok)
                rc = drmModeAtomicCommit(fd, req, DRM_MODE_ATOMIC_ALLOW_MODESET, NULL);
            drmModeAtomicFree(req);

            if (rc == 0) {
                p->fd = fd;
                p->fb = fb;
                p->handle = creq.handle;
                p->pitch = creq.pitch;
                p->height = creq.height;
                p->map = map;
                p->size = creq.size;
                drmModeFreeConnector(c);
                drmModeFreeResources(res);
                closedir(d);
                return 0;
            }

            fprintf(stderr, "commit falló en %s: %s\n", path, strerror(errno));
            drmModeRmFB(fd, fb);
            munmap(map, creq.size);
            drmDropMaster(fd);
            drmModeFreeConnector(c);
        }
        drmModeFreeResources(res);
        close(fd);
    }
    closedir(d);
    return -1;
}

/* Vuelca el lienzo horizontal (W x H) al búfer vertical del panel.
   Rotación idéntica a la de tiny-dfr: (lx, ly) -> (60 - ly, lx). */
static void blit(struct panel *p) {
    for (int ly = 0; ly < H; ly++) {
        int bx = 59 - ly;
        for (int lx = 0; lx < W; lx++) {
            uint32_t c = canvas[ly * W + lx];
            uint8_t *dst = p->map + (size_t)lx * p->pitch + (size_t)bx * 4;
            *(uint32_t *)dst = c;
        }
    }
    /* Sin esto el kernel no envía los píxeles al panel (es lo que hace
       tiny-dfr con `dirty_framebuffer`). */
    drmModeDirtyFB(p->fd, p->fb, NULL, 0);
}

/* ------------------------------------------------------------------------- */
/*  Teclado: lee /dev/input/event* para animar las patas                     */
/* ------------------------------------------------------------------------- */
#define MAX_FDS 32
static int in_fds[MAX_FDS];
static int in_n = 0;

static void open_inputs(void) {
    DIR *d = opendir("/dev/input");
    if (!d) return;
    struct dirent *e;
    while ((e = readdir(d)) && in_n < MAX_FDS) {
        if (strncmp(e->d_name, "event", 5) != 0) continue;
        char path[64];
        snprintf(path, sizeof(path), "/dev/input/%s", e->d_name);
        int fd = open(path, O_RDONLY | O_NONBLOCK);
        if (fd >= 0) in_fds[in_n++] = fd;
    }
    closedir(d);
}

static long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

/* Devuelve 1 si hubo alguna tecla pulsada desde la última llamada. */
static int poll_keys(void) {
    struct input_event ev;
    int pressed = 0;
    for (int i = 0; i < in_n; i++) {
        while (read(in_fds[i], &ev, sizeof(ev)) == (ssize_t)sizeof(ev)) {
            if (ev.type == 1 /* EV_KEY */ && ev.value == 1) pressed = 1;
        }
    }
    return pressed;
}

/* ------------------------------------------------------------------------- */
int main(int argc, char **argv) {
    if (argc >= 3 && strcmp(argv[1], "--render") == 0) {
        draw_frame(0, 1, 87);
        FILE *f = fopen(argv[2], "wb");
        if (!f) { perror("fopen"); return 1; }
        fprintf(f, "P6\n%d %d\n255\n", W, H);
        for (int i = 0; i < W * H; i++) {
            uint32_t c = canvas[i];
            unsigned char rgb[3] = { (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff };
            fwrite(rgb, 1, 3, f);
        }
        fclose(f);
        return 0;
    }

    if (argc < 2 || strcmp(argv[1], "--run") != 0) {
        fprintf(stderr, "uso: %s --run | --render out.ppm\n", argv[0]);
        return 1;
    }

    struct panel p = {0};
    if (open_panel(&p) < 0) {
        fprintf(stderr, "no se encontró el panel de la Touch Bar\n");
        return 1;
    }
    fprintf(stderr, "panel %ux%u, pitch %u\n", 64, p.height, p.pitch);

    open_inputs();
    fprintf(stderr, "%d dispositivos de entrada\n", in_n);

    int paw = 0;
    long anim_until = 0;
    int last_sec = -1;

    for (;;) {
        long t = now_ms();
        int pressed = poll_keys();

        if (pressed) {
            paw = (paw + 1) % 2;
            anim_until = t + 130;
        }

        int moving = (t < anim_until);
        time_t now = time(NULL);
        int sec = (int)(now % 2);

        if (moving || sec != last_sec) {
            last_sec = sec;
            draw_frame(moving ? paw : 2, sec, 87);  /* 87 = batería de prueba */
            blit(&p);
        }
        usleep(40000);  /* 25 fps */
    }
    return 0;
}
