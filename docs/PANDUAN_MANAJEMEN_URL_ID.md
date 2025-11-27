# Panduan Manajemen URL Setelah Operasi Delete (Hotwire / Stimulus)

Dokumentasi ini menjelaskan sistem manajemen URL yang kita terapkan untuk mencegah error `ActiveRecord::RecordNotFound` setelah melakukan penghapusan (delete) data melalui modal Turbo Frame. Ditulis dalam Bahasa Indonesia agar mudah dipahami oleh semua anggota tim.

---

## 1. Latar Belakang Masalah

Sebelum refactor:

1. User berada di halaman indeks (misal: `/users`).
2. Klik tombol Delete → modal konfirmasi terbuka pada URL: `/users/:id/confirm_delete`.
3. Data berhasil dihapus, tetapi URL browser tetap di `/users/:id/confirm_delete`.
4. User tekan refresh (F5) → Rails mencoba memuat record yang sudah terhapus → muncul error `ActiveRecord::RecordNotFound`.

Tujuan sistem ini:

- Mengembalikan URL ke halaman indeks setelah operasi delete tanpa reload penuh.
- Mempertahankan pengalaman SPA (Single Page Application) dengan Turbo.
- Menghindari error saat refresh.

---

## 2. Prinsip Desain (SOLID & Best Practice)

| Prinsip                     | Penerapan                                                                                                 |
| --------------------------- | --------------------------------------------------------------------------------------------------------- |
| SRP (Single Responsibility) | Controller hanya urus bisnis & flash, Turbo Stream koordinasi update UI, Stimulus hanya urus History API. |
| Open/Closed                 | Mudah ditambah method pushState tanpa ubah struktur utama.                                                |
| Dependency Inversion        | View & controller bergantung pada abstraksi (data attributes + Stimulus), bukan script inline.            |
| Security                    | Tidak pakai `eval()` / `<script>` inline, kompatibel CSP.                                                 |
| Maintainability             | Kode terpisah sesuai tanggung jawab, mudah dites & direview.                                              |

---

## 3. Arsitektur Tingkat Tinggi

```
Halaman Index (memiliki <div id="url-manager"></div>)
        │
        ▼
Modal konfirmasi (Turbo Frame)
        │ (submit delete)
        ▼
Controller#destroy (flash + respond_to turbo_stream)
        │
        ▼
destroy.turbo_stream.erb
  - remove row
  - close modal
  - update flash
  - update "url-manager" (render _url_updater)
        │
        ▼
Partial _url_updater.html.erb → elemen dengan data-controller="history"
        │
        ▼
Stimulus history_controller.js (connect → replaceState/pushState)
        │
        ▼
Browser History API (URL berubah ke /users, aman saat refresh)
```

---

## 4. Komponen yang Terlibat

1. Index Page: wajib punya `<div id="url-manager"></div>` di atas konten utama.
2. Turbo Stream (misal: `app/views/user_management/users/destroy.turbo_stream.erb`).
3. Partial Reusable: `app/views/shared/_url_updater.html.erb`.
4. Stimulus Controller: `app/javascript/controllers/history_controller.js`.
5. Modal system (sudah ada) tidak diubah selain pola destroy.

---

## 5. Cara Pakai (Langkah Implementasi Per Modul)

### A. Tambahkan container URL manager di file index

Contoh (Users):

```erb
<div id="flash_messages"><%= render "shared/flash" %></div>
<div id="url-manager"></div>
<!-- Konten tabel dst -->
```

### B. Pastikan controller destroy merespon turbo_stream

```ruby
def destroy
  authorize @user
  if @user.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "User deleted successfully." }
      format.html { redirect_to user_management_users_path, notice: "User deleted successfully." }
    end
  else
    redirect_to user_management_users_path, alert: "Failed to delete user."
  end
end
```

### C. Gunakan pola Turbo Stream di file `destroy.turbo_stream.erb`

```erb
<%= turbo_stream.remove dom_id(@user) %>
<%= turbo_stream.update "modal", "" %>
<%= turbo_stream.update "flash_messages", partial: "shared/flash" %>
<%= turbo_stream.update "url-manager",
    partial: "shared/url_updater",
    locals: { url: user_management_users_path } %>
```

### D. Partial `_url_updater.html.erb`

```erb
<%# url wajib, method opsional ("replaceState" atau "pushState") %>
<% method ||= "replaceState" %>
<div data-controller="history"
     data-history-url-value="<%= url %>"
     data-history-method-value="<%= method %>"></div>
```

### E. Stimulus Controller `history_controller.js`

```javascript
export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "replaceState" },
  };
  connect() {
    this.update();
  }
  replace() {
    if (this.hasUrlValue) window.history.replaceState({}, "", this.urlValue);
  }
  push() {
    if (this.hasUrlValue) window.history.pushState({}, "", this.urlValue);
  }
  urlValueChanged() {
    this.methodValue === "pushState" ? this.push() : this.replace();
  }
  update() {
    this.urlValueChanged();
  }
}
```

---

## 6. Logika Internal (Alur Eksekusi)

1. User klik tombol Delete → modal confirm tampil (Turbo Frame).
2. User klik tombol "Yes! Delete" → form delete submit (method: DELETE).
3. Controller `destroy` melakukan `@record.destroy` + set `flash.now`.
4. Rails memilih template `destroy.turbo_stream.erb` karena format turbo_stream.
5. Turbo Stream menghasilkan 4 aksi:
   - `remove`: hapus baris DOM terkait record.
   - `update modal`: kosongkan frame modal → modal tertutup oleh controller Stimulus lain.
   - `update flash_messages`: render ulang partial flash.
   - `update url-manager`: sisipkan elemen baru dengan data-controller="history".
6. Stimulus `history_controller` otomatis `connect()` → memanggil `update()`.
7. `update()` memanggil `urlValueChanged()` → memilih `replace()`.
8. Browser menjalankan `window.history.replaceState` ke path indeks.
9. User refresh halaman → tidak ada error karena URL sudah kembali ke indeks.

---

## 7. Kenapa Tidak Pakai `<script>` Inline?

| Alasan                   | Penjelasan                                                |
| ------------------------ | --------------------------------------------------------- |
| Eksekusi tidak konsisten | `<script>` yang disuntik via Turbo kadang tidak berjalan. |
| CSP                      | Produksi bisa blok inline script tanpa nonce.             |
| Keamanan                 | Inline JS rentan injeksi & sulit diaudit.                 |
| Testing                  | Stimulus mudah diuji, `<script>` sulit.                   |
| Reusability              | Stimulus reusable, `<script>` duplikasi.                  |

---

## 8. Ekstensi / Kustomisasi

| Kebutuhan                                            | Cara                                                               |
| ---------------------------------------------------- | ------------------------------------------------------------------ |
| Ingin menambah entry riwayat (bisa Back ke URL lama) | Gunakan `locals: { url: path, method: "pushState" }`               |
| Logging analytics                                    | Tambah pemanggilan fungsi tracking di dalam `replace()` / `push()` |
| Batasi perubahan URL tertentu                        | Validasi `this.urlValue` sebelum eksekusi                          |

Contoh pushState:

```erb
<%= turbo_stream.update "url-manager",
    partial: "shared/url_updater",
    locals: { url: filtered_users_path(params.slice(:role, :page)), method: "pushState" } %>
```

---

## 9. Checklist Per Modul

| Item                                     | Harus Ada                       | Status (contoh) |
| ---------------------------------------- | ------------------------------- | --------------- |
| Index punya `#url-manager`               | Ya                              | ✔               |
| destroy.turbo_stream pakai 4 pola        | Ya                              | ✔               |
| Partial `_url_updater` tersedia          | Ya                              | ✔               |
| Stimulus controller dipin/import         | Ya (`pin_all_from controllers`) | ✔               |
| Tidak ada file `turbo_stream_actions.js` | Sudah dihapus                   | ✔               |

---

## 10. Troubleshooting

| Gejala               | Penyebab Umum                          | Solusi                                                                          |
| -------------------- | -------------------------------------- | ------------------------------------------------------------------------------- |
| URL tidak berubah    | `#url-manager` tidak ada di index      | Tambahkan `<div id="url-manager"></div>`                                        |
| Flash tidak muncul   | Lupa update `flash_messages` di stream | Pastikan ada `turbo_stream.update "flash_messages"`                             |
| Modal tidak tertutup | Frame modal tidak dikosongkan          | Pastikan `update "modal", ""`                                                   |
| Error saat refresh   | URL masih di `confirm_delete`          | Pastikan partial url_updater dipanggil                                          |
| Stimulus tidak jalan | Controller tidak ter-load              | Pastikan importmap pin controllers & `import "controllers"` di `application.js` |

---

## 11. Contoh Lengkap (Users)

`destroy.turbo_stream.erb`

```erb
<%= turbo_stream.remove dom_id(@user) %>
<%= turbo_stream.update "modal", "" %>
<%= turbo_stream.update "flash_messages", partial: "shared/flash" %>
<%= turbo_stream.update "url-manager",
    partial: "shared/url_updater",
    locals: { url: user_management_users_path } %>
```

`_url_updater.html.erb`

```erb
<% method ||= "replaceState" %>
<div data-controller="history"
     data-history-url-value="<%= url %>"
     data-history-method-value="<%= method %>"></div>
```

`history_controller.js`

```javascript
export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "replaceState" },
  };
  connect() {
    this.update();
  }
  replace() {
    if (this.hasUrlValue) window.history.replaceState({}, "", this.urlValue);
  }
  push() {
    if (this.hasUrlValue) window.history.pushState({}, "", this.urlValue);
  }
  urlValueChanged() {
    this.methodValue === "pushState" ? this.push() : this.replace();
  }
  update() {
    this.urlValueChanged();
  }
}
```

Index Page bagian atas:

```erb
<div id="flash_messages"><%= render "shared/flash" %></div>
<div id="url-manager"></div>
```

---

## 12. Ringkasan Keuntungan

- Tidak ada error refresh setelah delete.
- Tidak perlu redirect penuh (hemat network & lebih cepat).
- Aman terhadap CSP & audit keamanan.
- Pola konsisten di semua modul (9 modul CRUD).
- Mudah diperluas untuk fitur lain (filter, pagination, dll).

---

## 13. Rekomendasi Lanjutan (Optional)

- Tambah test sistem: lakukan delete lalu assert `page.current_path == users_path`.
- Tambah telemetry ringan: kirim event ke analytics saat URL berubah.
- Standardisasi helper untuk generate `locals` jika pola makin kompleks.

---

## 14. Status Implementasi

Semua modul sudah mengikuti pola: Users, Roles, Workers, Categories, Blocks, Vehicles, Units, Work Order Rates, Work Orders Details.

Implementasi siap untuk di-commit dan direview.

---

## 15. FAQ Singkat

**Q: Bisa pakai pushState untuk delete?**
A: Bisa, tapi biasanya `replaceState` lebih tepat karena kita tidak ingin back button membawa user ke URL `confirm_delete`.

**Q: Kenapa tidak auto reload halaman?**
A: Reload penuh boros dan menghilangkan pengalaman cepat ala Turbo.

**Q: Aman kalau ada param query?**
A: Ya, selama URL diberikan dari sisi server (Rails helper) bukan input user mentah.

---

Ditulis: November 2025
Penanggung jawab: Tim Pengembangan UI/Hotwire
