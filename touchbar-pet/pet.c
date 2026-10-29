/*
 * touchbar-pet.c — Touch Bar con gato animado, capas y botones táctiles.
 *
 * Modos:
 *   CAT   (por defecto): gato animado que teclea + relámpago al escribir,
 *                        reloj, copo de nieve, batería, y botones [▶][fn]
 *   MEDIA                : brillo, volumen, play/pausa, anterior/siguiente
 *   FKEYS                : F1..F12 (se envían de verdad por uinput)
 *
 * El táctil se lee con libinput (dispositivo "Mac14,7 Touch Bar").
 * La salida es un dumb buffer DRM con commit atómico (appletbdrm).
 *
 * Uso: touchbar-pet --run | --render out.ppm
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
#include <sys/mman.h>
#include <sys/stat.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <signal.h>

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
#define YELLOW    0xe0af68

/* declaraciones adelantadas (save_shot las usa antes de definirse) */
static void draw_scene(int frame, int blink, int batt, long el, int typing);
static int battery_level(void);

static void px(int x, int y, uint32_t c) {
    if (x < 0 || y < 0 || x >= W || y >= H) return;
    canvas[y * W + x] = c;
}

static void fill(int x0, int y0, int w, int h, uint32_t c) {
    for (int y = y0; y < y0 + h; y++)
        for (int x = x0; x < x0 + w; x++) px(x, y, c);
}

static void rounded(int x0, int y0, int w, int h, int r, uint32_t c) {
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
            int dx = 0, dy = 0;
            if (x < r && y < r) { dx = r - x; dy = r - y; }
            else if (x >= w - r && y < r) { dx = x - (w - r - 1); dy = r - y; }
            else if (x < r && y >= h - r) { dx = r - x; dy = y - (h - r - 1); }
            else if (x >= w - r && y >= h - r) { dx = x - (w - r - 1); dy = y - (h - r - 1); }
            if (dx * dx + dy * dy <= r * r) px(x0 + x, y0 + y, c);
        }
}

static void disc(int cx, int cy, int r, uint32_t c) {
    for (int y = -r; y <= r; y++)
        for (int x = -r; x <= r; x++)
            if (x * x + y * y <= r * r) px(cx + x, cy + y, c);
}

static void line(int x0, int y0, int x1, int y1, uint32_t c) {
    int dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    int dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    for (;;) {
        px(x0, y0, c);
        if (x0 == x1 && y0 == y1) break;
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x0 += sx; }
        if (e2 <= dx) { err += dx; y0 += sy; }
    }
}

static void tri_right(int cx, int cy, int r, uint32_t c) {
    for (int i = 0; i < r; i++) {
        for (int yy = -i; yy <= i; yy++) px(cx + i, cy + yy, c);
    }
}
static void tri_left(int cx, int cy, int r, uint32_t c) {
    for (int i = 0; i < r; i++) {
        for (int yy = -i; yy <= i; yy++) px(cx - i, cy + yy, c);
    }
}

/* ------------------------------------------------------------------------- */
/*  Fuente 5x7 (mayúsculas, dígitos y símbolos)                              */
/* ------------------------------------------------------------------------- */
static const uint8_t FONT_DEF[128][7] = {
    [' '] = {0,0,0,0,0,0,0},
    ['+'] = {0,0x04,0x04,0x1f,0x04,0x04,0},
    ['-'] = {0,0,0,0x1f,0,0,0},
    ['<'] = {0,0x02,0x04,0x08,0x04,0x02,0},
    ['>'] = {0,0x08,0x04,0x02,0x04,0x08,0},
    ['!'] = {0x04,0x04,0x04,0x04,0,0x04,0},
    ['/'] = {0x01,0x02,0x02,0x04,0x08,0x08,0x10},
    ['A'] = {0x0e,0x11,0x11,0x1f,0x11,0x11,0x11},
    ['B'] = {0x1e,0x11,0x11,0x1e,0x11,0x11,0x1e},
    ['C'] = {0x0e,0x11,0x10,0x10,0x10,0x11,0x0e},
    ['D'] = {0x1e,0x11,0x11,0x11,0x11,0x11,0x1e},
    ['E'] = {0x1f,0x10,0x10,0x1e,0x10,0x10,0x1f},
    ['F'] = {0x1f,0x10,0x10,0x1e,0x10,0x10,0x10},
    ['G'] = {0x0e,0x11,0x10,0x17,0x11,0x11,0x0f},
    ['H'] = {0x11,0x11,0x11,0x1f,0x11,0x11,0x11},
    ['I'] = {0x0e,0x04,0x04,0x04,0x04,0x04,0x0e},
    ['J'] = {0x07,0x02,0x02,0x02,0x02,0x12,0x0c},
    ['K'] = {0x11,0x12,0x14,0x18,0x14,0x12,0x11},
    ['L'] = {0x10,0x10,0x10,0x10,0x10,0x10,0x1f},
    ['M'] = {0x11,0x1b,0x15,0x15,0x11,0x11,0x11},
    ['N'] = {0x11,0x19,0x15,0x13,0x11,0x11,0x11},
    ['O'] = {0x0e,0x11,0x11,0x11,0x11,0x11,0x0e},
    ['P'] = {0x1e,0x11,0x11,0x1e,0x10,0x10,0x10},
    ['Q'] = {0x0e,0x11,0x11,0x11,0x15,0x12,0x0d},
    ['R'] = {0x1e,0x11,0x11,0x1e,0x14,0x12,0x11},
    ['S'] = {0x0f,0x10,0x10,0x0e,0x01,0x01,0x1e},
    ['T'] = {0x1f,0x04,0x04,0x04,0x04,0x04,0x04},
    ['U'] = {0x11,0x11,0x11,0x11,0x11,0x11,0x0e},
    ['V'] = {0x11,0x11,0x11,0x11,0x11,0x0a,0x04},
    ['W'] = {0x11,0x11,0x11,0x15,0x15,0x15,0x0a},
    ['X'] = {0x11,0x11,0x0a,0x04,0x0a,0x11,0x11},
    ['Y'] = {0x11,0x11,0x0a,0x04,0x04,0x04,0x04},
    ['Z'] = {0x1f,0x01,0x02,0x04,0x08,0x10,0x1f},
    ['0'] = {0x0e,0x11,0x13,0x15,0x19,0x11,0x0e},
    ['1'] = {0x04,0x0c,0x04,0x04,0x04,0x04,0x0e},
    ['2'] = {0x0e,0x11,0x01,0x02,0x04,0x08,0x1f},
    ['3'] = {0x0e,0x11,0x01,0x06,0x01,0x11,0x0e},
    ['4'] = {0x02,0x06,0x0a,0x12,0x1f,0x02,0x02},
    ['5'] = {0x1f,0x10,0x1e,0x01,0x01,0x11,0x0e},
    ['6'] = {0x06,0x08,0x10,0x1e,0x11,0x11,0x0e},
    ['7'] = {0x1f,0x01,0x02,0x04,0x08,0x08,0x08},
    ['8'] = {0x0e,0x11,0x11,0x0e,0x11,0x11,0x0e},
    ['9'] = {0x0e,0x11,0x11,0x0f,0x01,0x02,0x0c},
};

static void text(int x, int y, int scale, uint32_t c, const char *s) {
    for (; *s; s++) {
        int ch = (unsigned char)*s;
        if (ch >= 'a' && ch <= 'z') ch -= 32;
        for (int r = 0; r < 7; r++)
            for (int b = 0; b < 5; b++)
                if (FONT_DEF[ch][r] & (1 << (4 - b)))
                    fill(x + b * scale, y + r * scale, scale, scale, c);
        x += 6 * scale;
    }
}

/* ------------------------------------------------------------------------- */
/*  Reloj (7 segmentos)                                                       */
/* ------------------------------------------------------------------------- */
static const uint8_t SEG[10] = {
    0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f
};

static void digit7(int x, int y, int w, int h, int th, int d, uint32_t c) {
    if (d == 1) { fill(x + w / 2 - th / 2, y, th, h, c); return; }
    uint8_t s = SEG[d % 10];
    if (s & 0x01) fill(x + th, y, w - 2 * th, th, c);
    if (s & 0x02) fill(x + w - th, y + th, th, h / 2 - th, c);
    if (s & 0x04) fill(x + w - th, y + h / 2, th, h / 2 - th, c);
    if (s & 0x08) fill(x + th, y + h - th, w - 2 * th, th, c);
    if (s & 0x10) fill(x, y + h / 2, th, h / 2 - th, c);
    if (s & 0x20) fill(x, y + th, th, h / 2 - th, c);
    if (s & 0x40) fill(x + th, y + h / 2 - th / 2, w - 2 * th, th, c);
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
    int x = cx - total / 2, y = cy - h / 2;
    digit7(x, y, w, h, th, tm.tm_hour / 10, BLUE); x += w + gap;
    digit7(x, y, w, h, th, tm.tm_hour % 10, BLUE); x += w + gap;
    if (blink) {
        int r = th / 2 + 1;
        disc(x + colon / 2, y + h / 3, r, BLUE);
        disc(x + colon / 2, y + 2 * h / 3, r, BLUE);
    }
    x += colon + gap;
    digit7(x, y, w, h, th, tm.tm_min / 10, BLUE); x += w + gap;
    digit7(x, y, w, h, th, tm.tm_min % 10, BLUE);
}

static void snowflake(int cx, int cy, int r, uint32_t c) {
    for (int a = 0; a < 6; a++) {
        double ang = a * 3.14159265 / 3.0;
        double dx = cos(ang), dy = sin(ang);
        for (int d = 0; d <= r; d++) {
            disc(cx + (int)(dx * d), cy + (int)(dy * d), 1, c);
            for (int dd = r / 2; dd <= r; dd += 4) {
                int bx = (int)(-dy * 4), by = (int)(dx * 4);
                disc(cx + (int)(dx * dd) + bx, cy + (int)(dy * dd) + by, 1, c);
                disc(cx + (int)(dx * dd) - bx, cy + (int)(dy * dd) - by, 1, c);
            }
        }
    }
}

static void battery(int bx, int by, int battery) {
    rounded(bx, by, 42, 20, 5, DIM);
    fill(bx + 2, by + 2, 38, 16, 0x101018);
    int fillw = (battery * 34) / 100;
    if (fillw > 0) fill(bx + 4, by + 4, fillw, 12, battery > 20 ? GREEN : PINK);
    rounded(bx + 42, by + 6, 4, 8, 1, DIM);
}

/* ------------------------------------------------------------------------- */
/*  Relámpago                                                                */
/* ------------------------------------------------------------------------- */
static uint32_t mix(uint32_t a, uint32_t b, int f) {
    int ar = (a >> 16) & 255, ag = (a >> 8) & 255, ab = a & 255;
    int br = (b >> 16) & 255, bg = (b >> 8) & 255, bb = b & 255;
    int r = ar + ((br - ar) * f) / 100;
    int g = ag + ((bg - ag) * f) / 100;
    int bl = ab + ((bb - ab) * f) / 100;
    return ((uint32_t)r << 16) | ((uint32_t)g << 8) | bl;
}

static void overlay_flash(int f) {
    for (int i = 0; i < W * H; i++)
        canvas[i] = mix(canvas[i], 0xffffff, f);
}

/* Tormenta: un rayo gigante que atraviesa TODA la barra, con ramas y flash. */
static void draw_storm(int flash) {
    int n = 16;
    int xs[17], ys[17];
    xs[0] = 120; ys[0] = 10;
    for (int i = 1; i <= n; i++) {
        xs[i] = 120 + i * ((W - 240) / n);
        int step = (i % 2) ? 9 : -7;
        ys[i] = ys[i - 1] + step;
        if (ys[i] < 6) ys[i] = 6;
        if (ys[i] > H - 6) ys[i] = H - 6;
    }
    /* ramas desde el rayo principal */
    for (int i = 2; i < n; i += 2) {
        int bx = xs[i] + 18, by = ys[i] - 14;
        line(xs[i], ys[i], bx, by, YELLOW);
        line(bx, by, bx + 8, by + 4, YELLOW);
        line(xs[i], ys[i], xs[i] - 14, ys[i] + 16, YELLOW);
    }
    /* resplandor (trazo más ancho y tenue) + trazo principal */
    for (int i = 0; i < n; i++) {
        line(xs[i], ys[i], xs[i + 1], ys[i + 1], 0x9a6b00);
        line(xs[i], ys[i] + 1, xs[i + 1], ys[i + 1] + 1, 0x9a6b00);
        line(xs[i], ys[i], xs[i + 1], ys[i + 1], YELLOW);
    }
    if (flash)
        overlay_flash(flash);
}

/* Relámpago anterior (ya no se usa, se sustituye por la tormenta) */
static void draw_bolt(int x, int seed) {
    int pts[][2] = {
        { x, 4 }, { x + 10, 20 }, { x + 4, 20 }, { x + 14, 40 },
        { x + 20, 24 }, { x + 14, 24 }, { x + 26, 2 }, { x, 4 }
    };
    for (int i = 0; i < 7; i++)
        line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], YELLOW);
    (void)seed;
}

/* ------------------------------------------------------------------------- */
/*  Fotos: sprite y frames                                                    */
/* ------------------------------------------------------------------------- */
typedef struct {
    int w, h;
    uint8_t *data;   /* RGB */
} Frame;

#define MAX_FRAMES 16
static Frame frames[MAX_FRAMES];
static int frame_count = 0;

static int load_ppm(const char *path, Frame *f) {
    FILE *fp = fopen(path, "rb");
    if (!fp) return -1;
    char magic[3] = {0};
    int w = 0, h = 0, max = 0;
    if (fscanf(fp, "%2s %d %d %d", magic, &w, &h, &max) != 4 || strcmp(magic, "P6") != 0) {
        fclose(fp);
        return -1;
    }
    fgetc(fp);
    size_t n = (size_t)w * h * 3;
    uint8_t *buf = malloc(n);
    if (!buf || fread(buf, 1, n, fp) != n) {
        free(buf);
        fclose(fp);
        return -1;
    }
    fclose(fp);
    f->w = w;
    f->h = h;
    f->data = buf;
    return 0;
}

static int name_cmp(const struct dirent **a, const struct dirent **b) {
    return strcmp((*a)->d_name, (*b)->d_name);
}

static void load_frames(void) {
    struct dirent **list = NULL;
    int n = scandir("/etc/touchbar-pet/frames", &list, NULL, name_cmp);
    for (int i = 0; i < n && frame_count < MAX_FRAMES; i++) {
        const char *name = list[i]->d_name;
        size_t len = strlen(name);
        if (len < 4 || strcmp(name + len - 4, ".ppm") != 0) continue;
        char path[256];
        snprintf(path, sizeof(path), "/etc/touchbar-pet/frames/%s", name);
        if (load_ppm(path, &frames[frame_count]) == 0)
            frame_count++;
    }
    for (int i = 0; i < n; i++) free(list[i]);
    free(list);
    fprintf(stderr, "%d fotogramas cargados\n", frame_count);
}

static void draw_frame_at(int idx, int x0, int y0) {
    if (idx < 0 || idx >= frame_count) return;
    Frame *f = &frames[idx];
    for (int y = 0; y < f->h && y0 + y < H; y++)
        for (int x = 0; x < f->w && x0 + x < W; x++) {
            uint8_t *p = f->data + ((size_t)y * f->w + x) * 3;
            uint32_t c = ((uint32_t)p[0] << 16) | ((uint32_t)p[1] << 8) | p[2];
            px(x0 + x, y0 + y, c);
        }
}

/* ------------------------------------------------------------------------- */
/*  Modos, botones y acciones                                                 */
/* ------------------------------------------------------------------------- */
enum { MODE_CAT = 0, MODE_MEDIA, MODE_FKEYS };

enum {
    ACT_NONE = 0,
    ACT_CAT, ACT_MEDIA, ACT_FKEYS,
    ACT_BRIGHT_DOWN, ACT_BRIGHT_UP,
    ACT_VOL_DOWN, ACT_VOL_UP, ACT_MUTE,
    ACT_PLAY, ACT_PREV, ACT_NEXT,
    ACT_FKEY_1, ACT_FKEY_12 = ACT_FKEY_1 + 11,
};

typedef struct { int x, y, w, h; int act; const char *label; int icon; } Button;
/* icon: 0=texto,1=play,2=prev,3=next,4=sun,5=speaker,6=mute,7=back,8=cat */

/* Modo gato: botones GRANDES a la derecha, justo después de la batería. */
static Button cat_buttons[] = {
    { W - 196, 12, 92, 36, ACT_MEDIA, NULL, 1 },   /* ▶ */
    { W - 98, 12, 92, 36, ACT_FKEYS, "FN", 0 },
    { 0, 0, 0, 0, 0, NULL, 0 }
};

static Button media_buttons[] = {
    { 48, 12, 50, 36, ACT_BRIGHT_DOWN, NULL, 4 },
    { 102, 12, 50, 36, ACT_BRIGHT_UP, NULL, 4 },
    { 156, 12, 50, 36, ACT_VOL_DOWN, NULL, 5 },
    { 210, 12, 50, 36, ACT_VOL_UP, NULL, 5 },
    { 264, 12, 50, 36, ACT_MUTE, NULL, 6 },
    { 318, 12, 54, 36, ACT_PREV, NULL, 2 },
    { 376, 12, 54, 36, ACT_PLAY, NULL, 1 },
    { 434, 12, 54, 36, ACT_NEXT, NULL, 3 },
    /* volver al gato: a la derecha del todo */
    { W - 196, 12, 92, 36, ACT_CAT, NULL, 7 },
    { 0, 0, 0, 0, 0, NULL, 0 }
};

static Button fkey_buttons[13];

static int mode = MODE_CAT;
static int redraw_needed = 0;

static Button *current_buttons(void) {
    switch (mode) {
        case MODE_MEDIA: return media_buttons;
        case MODE_FKEYS: return fkey_buttons;
        default: return cat_buttons;
    }
}

static void fkeys_init(void) {
    int bw = (W - 40) / 12;
    for (int i = 0; i < 12; i++) {
        static char lbl[16];
        snprintf(lbl, sizeof(lbl), "F%d", i + 1);
        fkey_buttons[i].x = 40 + i * bw;
        fkey_buttons[i].y = 8;
        fkey_buttons[i].w = bw - 6;
        fkey_buttons[i].h = 44;
        fkey_buttons[i].act = ACT_FKEY_1 + i;
        fkey_buttons[i].label = strdup(lbl);
        fkey_buttons[i].icon = 0;
    }
    fkey_buttons[12] = (Button){ W - 196, 12, 92, 36, ACT_CAT, NULL, 7 };
}

static void emit_key(int code);

static void execute(int act) {
    redraw_needed = 1;
    switch (act) {
        case ACT_CAT:   mode = MODE_CAT;   break;
        case ACT_MEDIA: mode = MODE_MEDIA; break;
        case ACT_FKEYS: mode = MODE_FKEYS; break;
        case ACT_BRIGHT_DOWN: system("brightnessctl set 5%-"); break;
        case ACT_BRIGHT_UP:   system("brightnessctl set 5%+"); break;
        case ACT_VOL_DOWN:    system("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"); break;
        case ACT_VOL_UP:      system("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"); break;
        case ACT_MUTE:        system("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"); break;
        case ACT_PLAY:        system("playerctl play-pause"); break;
        case ACT_PREV:        system("playerctl previous"); break;
        case ACT_NEXT:        system("playerctl next"); break;
        default:
            if (act >= ACT_FKEY_1 && act <= ACT_FKEY_12) {
                emit_key(KEY_F1 + (act - ACT_FKEY_1));
            }
    }
}

/* ------------------------------------------------------------------------- */
/*  uinput: emite teclas F                                                   */
/* ------------------------------------------------------------------------- */
static int uinput_fd = -1;

static void emit_key(int code) {
    if (uinput_fd < 0) return;
    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = EV_KEY; ev.code = code; ev.value = 1;
    write(uinput_fd, &ev, sizeof(ev));
    memset(&ev, 0, sizeof(ev));
    ev.type = EV_SYN; ev.code = SYN_REPORT; ev.value = 0;
    write(uinput_fd, &ev, sizeof(ev));
    memset(&ev, 0, sizeof(ev));
    ev.type = EV_KEY; ev.code = code; ev.value = 0;
    write(uinput_fd, &ev, sizeof(ev));
    memset(&ev, 0, sizeof(ev));
    ev.type = EV_SYN; ev.code = SYN_REPORT; ev.value = 0;
    write(uinput_fd, &ev, sizeof(ev));
}

static void uinput_init(void) {
    uinput_fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (uinput_fd < 0) return;
    ioctl(uinput_fd, UI_SET_EVBIT, EV_KEY);
    for (int k = KEY_F1; k <= KEY_F12; k++) ioctl(uinput_fd, UI_SET_KEYBIT, k);
    ioctl(uinput_fd, UI_SET_KEYBIT, KEY_LEFTMETA);
    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    snprintf(us.name, sizeof(us.name), "touchbar-pet");
    us.id.bustype = BUS_USB;
    if (ioctl(uinput_fd, UI_DEV_SETUP, &us) == 0)
        ioctl(uinput_fd, UI_DEV_CREATE);
}

/* ------------------------------------------------------------------------- */
/*  Dibujado de iconos y botones                                             */
/* ------------------------------------------------------------------------- */
static void icon_play(int cx, int cy, uint32_t c) { tri_right(cx - 5, cy, 10, c); }
static void icon_prev(int cx, int cy, uint32_t c) {
    tri_left(cx + 5, cy, 10, c); tri_left(cx + 13, cy, 10, c);
}
static void icon_next(int cx, int cy, uint32_t c) {
    tri_right(cx - 5, cy, 10, c); tri_right(cx + 3, cy, 10, c);
}
static void icon_sun(int cx, int cy, int plus, uint32_t c) {
    disc(cx - (plus ? 4 : 4), cy, 7, c);
    for (int a = 0; a < 4; a++) {
        double ang = a * 3.14159265 / 2.0;
        line(cx + (int)(cos(ang) * 10), cy + (int)(sin(ang) * 10),
             cx + (int)(cos(ang) * 13), cy + (int)(sin(ang) * 13), c);
    }
    int sx = cx + (plus ? 12 : -12);
    text(sx - 4, cy - 3, 1, c, plus ? "+" : "-");
}
static void icon_speaker(int cx, int cy, int muted, uint32_t c) {
    fill(cx - 12, cy - 5, 7, 10, c);
    tri_right(cx - 5, cy, 9, c);
    if (muted) {
        line(cx + 4, cy - 8, cx + 14, cy + 8, PINK);
        line(cx + 4, cy + 8, cx + 14, cy - 8, PINK);
    }
}
static void icon_back(int cx, int cy, uint32_t c) {
    tri_left(cx + 6, cy, 9, c);
    fill(cx - 6, cy - 6, 9, 12, c);
}
static void icon_cat(int cx, int cy, uint32_t c) {
    disc(cx, cy, 8, c);
    /* orejas */
    line(cx - 6, cy - 4, cx - 9, cy - 12, c);
    line(cx + 6, cy - 4, cx + 9, cy - 12, c);
}

static void draw_icon(int icon, int cx, int cy, uint32_t c) {
    switch (icon) {
        case 1: icon_play(cx, cy, c); break;
        case 2: icon_prev(cx, cy, c); break;
        case 3: icon_next(cx, cy, c); break;
        case 4: icon_sun(cx, cy, 0, c); break;
        case 5: icon_speaker(cx, cy, 0, c); break;
        case 6: icon_speaker(cx, cy, 1, c); break;
        case 7: icon_back(cx, cy, c); break;
        case 8: icon_cat(cx, cy, c); break;
    }
}

static void draw_buttons(Button *btns) {
    for (Button *b = btns; b->w; b++) {
        rounded(b->x, b->y, b->w, b->h, 8, SURFACE);
        /* borde sutil */
        for (int i = 0; i < b->w; i++) {
            px(b->x + i, b->y, BORDER);
            px(b->x + i, b->y + b->h - 1, BORDER);
        }
        int cx = b->x + b->w / 2;
        int cy = b->y + b->h / 2;
        if (b->icon) draw_icon(b->icon, cx, cy, FG);
        else if (b->label) text(cx - 3 * 6 / 2, cy - 4, 1, FG, b->label);
    }
}

/* ------------------------------------------------------------------------- */
/*  Entrada: teclado (evdev) + táctil (libinput)                             */
/* ------------------------------------------------------------------------- */
#define MAX_FDS 32
static int in_fds[MAX_FDS];
static int in_n = 0;

/* --- Táctil de la Touch Bar (evdev directo) --- */
static int touchbar_fd = -1;
static int tb_x_max = 23045;          /* ABS_MT_POSITION_X máx (leído al abrir) */
static int tb_y_max = 23045;
static int touch_down = 0;
static int touch_x = -1, touch_y = -1;
static int down_btn = -1;

static void open_touchbar(void) {
    DIR *d = opendir("/dev/input");
    if (!d) return;
    struct dirent *e;
    while ((e = readdir(d))) {
        if (strncmp(e->d_name, "event", 5) != 0) continue;
        char path[64];
        snprintf(path, sizeof(path), "/dev/input/%s", e->d_name);
        int fd = open(path, O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;
        char name[256] = {0};
        if (ioctl(fd, EVIOCGNAME(256), name) >= 0 && strstr(name, "Touch Bar")) {
            touchbar_fd = fd;
            struct input_absinfo ai;
            if (ioctl(fd, EVIOCGABS(ABS_MT_POSITION_X), &ai) == 0 && ai.maximum > 0)
                tb_x_max = ai.maximum + 1;
            if (ioctl(fd, EVIOCGABS(ABS_MT_POSITION_Y), &ai) == 0 && ai.maximum > 0)
                tb_y_max = ai.maximum + 1;
            fprintf(stderr, "táctil en %s (x 0..%d)\n", e->d_name, tb_x_max - 1);
            break;
        }
        close(fd);
    }
    closedir(d);
}

static void touch_event(int code, int value) {
    if (code == 53)      touch_x = value * W / tb_x_max;
    else if (code == 54) touch_y = value * H / tb_y_max;
    else if (code == BTN_TOUCH) {
        if (value == 1) {
            touch_down = 1;
            down_btn = -1;
            Button *b;
            for (b = current_buttons(); b->w; b++)
                if (touch_x >= b->x && touch_x < b->x + b->w &&
                    touch_y >= b->y && touch_y < b->y + b->h)
                    break;
            if (b->w) down_btn = (int)(b - current_buttons());
        } else if (value == 0 && touch_down) {
            touch_down = 0;
            if (down_btn >= 0) {
                Button *b = &current_buttons()[down_btn];
                if (touch_x >= b->x && touch_x < b->x + b->w &&
                    touch_y >= b->y && touch_y < b->y + b->h)
                    execute(b->act);
            }
            down_btn = -1;
        }
    }
}


static void open_inputs(void) {
    DIR *d = opendir("/dev/input");
    if (!d) return;
    struct dirent *e;
    while ((e = readdir(d)) && in_n < MAX_FDS) {
        if (strncmp(e->d_name, "event", 5) != 0) continue;
        char path[64];
        snprintf(path, sizeof(path), "/dev/input/%s", e->d_name);
        int fd = open(path, O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;
        /* el táctil de la Touch Bar se procesa aparte */
        char name[256] = {0};
        if (ioctl(fd, EVIOCGNAME(256), name) >= 0 && strstr(name, "Touch Bar")) {
            close(fd);
            continue;
        }
        in_fds[in_n++] = fd;
    }
    closedir(d);
}

static int pressed_keys = 0;

static void poll_keys(void) {
    struct input_event ev;
    for (int i = 0; i < in_n; i++) {
        while (read(in_fds[i], &ev, sizeof(ev)) == (ssize_t)sizeof(ev))
            if (ev.type == EV_KEY && ev.value == 1) pressed_keys++;
    }
    if (touchbar_fd >= 0) {
        while (read(touchbar_fd, &ev, sizeof(ev)) == (ssize_t)sizeof(ev)) {
            if (ev.type == EV_ABS) touch_event(ev.code, ev.value);
            else if (ev.type == EV_KEY && ev.code == BTN_TOUCH) touch_event(ev.code, ev.value);
        }
    }
}

/* ------------------------------------------------------------------------- */
/*  Salida DRM                                                               */
/* ------------------------------------------------------------------------- */
struct panel {
    int fd; uint32_t fb, handle, pitch, height;
    uint8_t *map; size_t size;
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
            if (m->vdisplay / m->hdisplay < 30) { drmModeFreeConnector(c); continue; }
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
            if (drmSetMaster(fd) != 0) { drmModeFreeConnector(c); continue; }
            struct drm_mode_create_dumb creq = {0};
            creq.width = 64; creq.height = m->vdisplay; creq.bpp = 32;
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
            drmModeCreatePropertyBlob(fd, m, sizeof(*m), &blob);
            int ok = 1;
            ok &= add_prop(fd, req, c->connector_id, DRM_MODE_OBJECT_CONNECTOR, "CRTC_ID", crtc) == 0;
            if (blob) ok &= add_prop(fd, req, crtc, DRM_MODE_OBJECT_CRTC, "MODE_ID", blob) == 0;
            ok &= add_prop(fd, req, crtc, DRM_MODE_OBJECT_CRTC, "ACTIVE", 1) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "FB_ID", fb) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_ID", crtc) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_X", 0) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_Y", 0) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_W", (uint64_t)m->hdisplay << 16) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "SRC_H", (uint64_t)m->vdisplay << 16) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_X", 0) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_Y", 0) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_W", (uint64_t)m->hdisplay) == 0;
            ok &= add_prop(fd, req, plane, DRM_MODE_OBJECT_PLANE, "CRTC_H", (uint64_t)m->vdisplay) == 0;
            int rc = -1;
            if (ok) rc = drmModeAtomicCommit(fd, req, DRM_MODE_ATOMIC_ALLOW_MODESET, NULL);
            drmModeAtomicFree(req);
            if (rc == 0) {
                p->fd = fd; p->fb = fb; p->handle = creq.handle;
                p->pitch = creq.pitch; p->height = creq.height;
                p->map = map; p->size = creq.size;
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

static void blit(struct panel *p) {
    for (int ly = 0; ly < H; ly++) {
        int bx = 59 - ly;
        for (int lx = 0; lx < W; lx++) {
            uint32_t c = canvas[ly * W + lx];
            *(uint32_t *)(p->map + (size_t)lx * p->pitch + (size_t)bx * 4) = c;
        }
    }
    drmModeDirtyFB(p->fd, p->fb, NULL, 0);
}

static void backlight_on(void) {
    const char *dirs[] = { "/sys/class/backlight/228600000.dsi.0", NULL };
    for (int i = 0; dirs[i]; i++) {
        char path[128];
        snprintf(path, sizeof(path), "%s/max_brightness", dirs[i]);
        FILE *f = fopen(path, "r");
        if (!f) continue;
        int max = 255;
        if (fscanf(f, "%d", &max) != 1) max = 255;
        fclose(f);
        snprintf(path, sizeof(path), "%s/brightness", dirs[i]);
        f = fopen(path, "w");
        if (!f) continue;
        fprintf(f, "%d\n", max * 85 / 100);
        fclose(f);
    }
}

/* Guarda la pantalla actual en /tmp/touchbar-shot.ppm (para revisarla).
   SIGUSR2 = guarda una escena "de demostración" (tormenta activa). */
static void save_shot(int sig) {
    if (sig == SIGUSR2)
        draw_scene(frame_count ? frame_count / 2 : 0, 1, battery_level(), 60, 1);
    FILE *f = fopen("/tmp/touchbar-shot.ppm", "wb");
    if (f) {
        fprintf(f, "P6\n%d %d\n255\n", W, H);
        for (int i = 0; i < W * H; i++) {
            uint32_t c = canvas[i];
            unsigned char rgb[3] = { (c >> 16) & 255, (c >> 8) & 255, c & 255 };
            fwrite(rgb, 1, 3, f);
        }
        fclose(f);
        fprintf(stderr, "captura guardada\n");
    }
    (void)sig;
}

static long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

static int battery_level(void) {
    FILE *f = fopen("/sys/class/power_supply/macsmc-battery/capacity", "r");
    if (!f) return 87;
    int v = 87;
    if (fscanf(f, "%d", &v) != 1) v = 87;
    fclose(f);
    return v;
}

/* ------------------------------------------------------------------------- */
static void draw_scene(int frame, int blink, int batt, long el, int typing) {
    fill(0, 0, W, H, BG);
    fill(0, 0, W, 1, BORDER);
    fill(0, H - 1, W, 1, BORDER);

    if (mode == MODE_CAT) {
        draw_buttons(cat_buttons);

        int fx = (frame_count ? frame : -1);
        if (fx >= 0)
            draw_frame_at(fx, 100, (H - frames[fx].h) / 2);

        /* tormenta: rayo que atraviesa toda la barra + flash al empezar */
        if (typing) {
            int flash = 0;
            if (el < 90) flash = 65;
            else if (el < 170) flash = 40;
            else if (el < 240) flash = 22;
            draw_storm(flash);
        }

        draw_time(1010, 30, 30, blink);
        snowflake(1700, 30, 15, PURPLE);
        battery(W - 250, 21, batt);
    } else if (mode == MODE_MEDIA) {
        draw_buttons(media_buttons);
        draw_time(W - 300, 30, 26, blink);
        battery(W - 250, 21, batt);
    } else {
        draw_buttons(fkey_buttons);
        battery(W - 250, 21, batt);
    }
}

int main(int argc, char **argv) {
    if (argc >= 3 && strcmp(argv[1], "--render") == 0) {
        load_frames();
        draw_scene(0, 1, 87, 0, 0);
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

    backlight_on();
    load_frames();
    open_touchbar();
    open_inputs();
    uinput_init();
    fkeys_init();
    signal(SIGUSR1, save_shot);
    signal(SIGUSR2, save_shot);

    int frame = 0;
    long anim_until = 0;
    long typing_start = 0;
    int last_sec = -1;
    int key_state = 0;

    struct pollfd pfds[4];
    int nfds = 0;
    if (touchbar_fd >= 0) {
        pfds[nfds].fd = touchbar_fd;
        pfds[nfds].events = POLLIN;
        nfds++;
    }
    for (int i = 0; i < in_n && nfds < 4; i++) {
        pfds[nfds].fd = in_fds[i];
        pfds[nfds].events = POLLIN;
        nfds++;
    }
    for (;;) {
        int r = poll(pfds, nfds, 40);
        if (r > 0)
            poll_keys();

        long t = now_ms();
        if (pressed_keys > 0) {
            /* el rayo y el tecleo duran un poco tras cada pulsación */
            typing_start = t;
            anim_until = t + 700;
            key_state = 1;
            pressed_keys = 0;
        }
        int typing = (t < anim_until);
        if (!typing) key_state = 0;
        /* animación fluida: el fotograma avanza por tiempo (cada 70 ms) */
        if (typing && frame_count > 0)
            frame = (int)((t / 70) % frame_count);
        else
            frame = 0;

        int sec = (int)(time(NULL) % 2);
        if (redraw_needed || typing || sec != last_sec) {
            redraw_needed = 0;
            last_sec = sec;
            int fi = typing ? frame : 0;
            draw_scene(fi, sec, battery_level(), typing ? (t - typing_start) : 0, key_state);
            blit(&p);
        }
    }
    return 0;
}
