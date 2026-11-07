# Bölümler, kalıcı ilerleme ve üst harita

## Beş bölüm

| Bölüm | Hedef | Orman |
| --- | ---: | --- |
| 1 — Kavak Korusu | 12 ağaç | Kavaklarla temel kesim ve zincir |
| 2 — Çam Patikası | 18 ağaç | Kavak/çam karışımı |
| 3 — Ladin Yamacı | 24 ağaç | İlk ladinler ve daha dayanıklı gövdeler |
| 4 — Sisli Vadi | 30 ağaç | Çam ve ladin ağırlıklı |
| 5 — Altın Meşe Yolu | 36 ağaç | Ladin ağırlıklı son rota |

Her bölüm, önceki bölümler tamamlanınca açılır. Ağaç dağılımı, sabit yerleşimi ve hafif ortam tonu farklıdır. Yeni bir ağaç türü/görsel uydurulmamıştır; mevcut ağaçlar kullanılır. Altın Meşe Yolu bölümün adıdır, yeni kesilebilir ağaç türü değildir.

## İlerleme ve harita

- Oyunun üstünde beş durağın, mevcut bölümün, kesilen/hedef ağaç sayısının ve ilerledikçe hareket eden Pipsy simgesinin yer aldığı rota haritası var.
- Yeşil duraklar tamamlanan, altın renkli durak seçili, soluk duraklar kilitli bölümleri gösterir. Alt çizgi mevcut bölümün tamamlanma oranını gösterir.
- Kamp haritasında açık bölümün üzerine tıklanır; Bölüme Başla ile o bölüme girilir. Tamamlanan bölümlerde düğme Bölümü Tekrar Oyna olur.
- Bütün ağaçlar yere indiğinde vardiya kendiliğinden biter. Sonuçta Sonraki Bölüm veya Kampa Dön seçilir. Son bölümde Harita Tamamlandı mesajı çıkar.
- Süre bittiğinde temizlenen ağaçlar kaydedilir; sonraki vardiyada aynı yerde kütük olarak kalırlar. Hasar almış ama henüz yere inmemiş ağaçlar kesilmiş sayılmaz.
- Pencere kapatılırken de yere inmiş ağaçların kazancı ve ilerlemesi kaydedilir. Kayıt tekrar uygulanıp ikinci kez para verilmez.
- Ödeme ve bölüm kontrol noktası aynı kayıt işlemindedir. Kaydı yüklemek, önceden parası verilen ağaçları yeniden üretmez. Eski altın/geliştirme/hikâye kayıtları korunur; eski derinlikten hayali bölüm tamamlaması çıkarılmaz.
- Bir bölüm yeniden oynandığında hedef o oynanış için sıfırdan başlar; önceki tamamlanma ve açık bölümler korunur. Böylece geliştirmeler için yeniden altın kazanılabilir.

## Ses düzeltmesi

Rahatsız eden `creak1.ogg` ve `creak2.ogg` kapı benzeri gıcırdama kayıtları oyunun dosyalarından ve ses seçimlerinden çıkarılmıştır. Devrilme başlangıcında daha düşük seviyeli, kısa bir ahşap darbe kullanılır. Diğer efektler, ambiyans ve ses ayarları korunur. Ses örneği de yeni miksle güncellenir.

## Doğrulama

Godot 4.7.2 ile 11 test grubu geçti. Bölüm testleri; sonlu üretimi, sabit yerleşimi, kalıcı kütükleri, kilit sırasını, kayıtla birlikte ödeme yapılmasını, tekrar oynanışı, eski kayıt uyumunu, kamera sınırlarını, pencere kapatmada kaydı, kamp haritasındaki gerçek düğmeleri ve Sonraki Bölüm düğmesinden yeni sahneye geçişi kapsar. Ses testi kullanılan bütün dosya adlarında gıcırdama kayıtlarının bulunmadığını kontrol eder.

Kamp/oyun haritaları, bölüm tamamlama ve harita bitiş ekranları Godot ile çizdirilerek kontrol edildi. Önizlemeler örnek durum kullanır ve oyuncunun gerçek kaydını değiştirmez.

Önceki 33–34 vardiyalık bütün geliştirmeleri bitirme ölçümü sonsuz orman benchmark'ına aittir; yeni sonlu kampanyanın bitiş süresi olarak değerlendirilmemelidir.
