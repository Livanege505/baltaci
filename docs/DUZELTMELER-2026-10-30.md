# Baltacı: fare, ekonomi ve oynanış düzeltmeleri

## Fare ve kamera

- Kampın Ayarlar menüsünde ve vardiyada ESC ile açılan menüde kalıcı tercihler var: kenardan kaydırma, otomatik kamera takibi, kamera hızı, balta yumuşatma, otomatik vuruş ve ekran sarsıntısı.
- Yumuşatma sıfırken balta fareyi doğrudan takip eder. Hedef işareti her zaman gerçek nişan noktasını gösterir; darbe anında balta aynı noktaya gelir.
- Darbe duraksaması fare takibini yavaşlatmaz. Nişan hesabı ekran sarsıntısını dikkate alır.
- Arayüzün üstündeyken veya pencere dışındayken balta vurmaz. Paydos düğmesine yaklaşmak kenar kaydırmasını tetiklemez.
- Otomatik vuruş kapatılırsa kesmek için sol fareyi basılı tutmak gerekir.
- Hedef ağacın adı, kalan canı ve devrilme yönü ekranın altında görünür.

## Vardiya

- ESC oyunu durdurur; aynı menüden ayarlar değiştirilebilir. ESC veya Devam et ile devam edilir.
- Alt+Tab/pencere odağı kaybı vardiyayı otomatik durdurur. Geri dönünce oyuncunun devam etmesi beklenir.
- Vardiya süresi gerçek zamana göre sayılır. Vuruş animasyonunun kısa yavaşlamaları artık süreyi uzatmaz.
- Tur sonundaki yarım vuruş tamamlanır; sonuçlar gösterilmeden kampa dönülemez. Sonuç HUD'ı ödenen zincirle aynı değeri gösterir.

## Ekonomi

| Geliştirme | Önce | Sonra | Gerekçe |
| --- | --- | --- | --- |
| Keskin Balta | 25 seviye, fiyat büyümesi 1.36 | 29 seviye, büyüme 1.30 | Son seviye 92 hasara ulaşır; 90 canlı ladini tek vuruşta keser. Önceki seviye 89 hasardır. |
| Ağır Devrilme | Seviye başına 0.012; fiyat büyümesi 1.60 | Seviye başına 0.011; büyüme 1.55; 15 seviye korunur | Son seviye ladinden ladine 90.3 devrilme hasarı verir; önceki seviye 85.68'dir. Son satın alma gerçek bir eşik açar. |
| Şanslı Vuruş | İlk fiyat 220, büyüme 1.60 | İlk fiyat 60, büyüme 1.50 | Erken oyunda balta hasarına göre çok pahalı olan kritik seçeneğini erişilebilir yapar. |

Diğer iki geliştirme korunmuştur. Eski kayıtlardaki seviye sayıları korunur; istatistikler yeni denge değerleriyle hesaplanır.

Simülatör gerçek balta temasını, vuruşlar arası beklemeyi, darbe duraksamasını, gerçek vardiya saatini ve ekran sarsıntısındaki hedef konumunu kullanır. Son tam ilerleme koşusunda bütün geliştirmeler, ağaç değiştirmede kayıp vuruş yokken 33, bir vuruş kaybedilirken 34 vardiyada tamamlandı. İlk satın alma ilk vardiyada yapılabildi. Geliştirmelerin toplam maliyeti 294.788 altındır. Sekiz farklı ormanda taban gelir ortalaması bu iki nişan modelinde 100/101 altındı. Hedef yaklaşık 30–40 vardiyadır; bu bir insan oyun testi veya sabit bitirme süresi garantisi değildir. Ekran görüntüsü modu güçlendirilmiş bir önizlemedir ve ekonomi ölçümü için kullanılmamalıdır.

## Kayıt güvenliği ve hikâye

- Bozuk ana kayıtta en yeni geçerli geçici/yedek kayıt seçilir. Testler, simülasyon ve önizlemeler gerçek kayıtta kurtarma işlemi bile yapmaz.
- Geçersiz/negatif/sonsuz tomruk sayıları ödeme hesabını bozamaz. Durum anlık görüntüleri birbirinin sözlüklerini değiştiremez.
- İlerlemeyi sıfırlamak eski vardiya özetini ve hikâye kuyruğunu temizler; fare tercihleri korunur.
- Önceden oluşturulan uzak ağaçlar keşif sayılmaz. Derinlik ve ilk tür bildirimi oyuncunun ulaşıp vurduğu ağaca göre ilerler.
- Kemal'in zincir görevi havada devrilmekte olan ağaçlara göre ödül vermez; zincirde gerçekten yere inen ağaçları sayar.
- Harita parçası ilgili iki konuşmada görsel kart olarak açılır. Eksik görsel oyunu çökertmez.
- Kampa giriş konuşması ayarlar menüsünün üzerine açılmaz.
- Kampın arka ağaçları küçültülüp solduruldu; ağaç diplerindeki yeşil gölgeler nötrleştirildi.

## Ses katmanı

- Balta darbesi ve kritik vuruş, boşta balta savurma, ağaç çatırdaması ve yere çarpma, zincir dönüm noktaları, satın alma/altın, menü tıklaması, vardiya başlangıcı/sonucu ve konuşma sayfası sesleri eklendi.
- Kamp ve ormanda düşük seviyeli, kesintisiz döngülü bir orman ambiyansı çalar. Sahne geçişleri döngüyü yeniden başlatmaz.
- Ayarlar menüsü Fare ve Ses sekmelerine ayrıldı. Ses sekmesinde genel/efekt/ambiyans seviyeleri, tüm sesleri kapatma ve Sesi dene düğmesi var. Eski ayar dosyaları yeni varsayılanları otomatik alır.
- Dünya sesleri duraklatılır; duraklatma menüsündeki düğmeler duyulmaya devam eder. Pencere odağı kaybolduğunda bütün oyun sesi kesilir.
- Uzun zincirler sınırlı ses havuzu ve olay aralıklarıyla dengelenir. Son miksin tepe seviyelerini sınırlayan bir limiter bulunur. Kozmetik ses seçimi ekonomi/orman rastgeleliğini değiştirmez.
- Kenney'nin Impact Sounds, RPG Audio ve Interface Sounds paketleri ile TinyWorlds'ün Forest Ambience eseri kullanıldı. Kaynak ve CC0 lisansları [audio/CREDITS.md](../audio/CREDITS.md) ve `audio/licenses/` içinde korunur.

## Doğrulama

Godot 4.7.2 ile `tests/run_all.gd` içindeki on test grubunun tamamı geçti. Yeni kontroller; ses dosyalarının gerçekten çözümlenmesini, olay/ses bağlantılarını, ses havuzunu, miks/odak/duraklatma davranışını, ses tercihlerinin yeniden yüklenmesini, gerçek ESC olaylarını, basılı fare ile kesimi, duraklatmada süreyi, gerçek zamanlı saati, sarsıntılı nişanı, keşfi, yere inen zincir görevini, kayıt güvenliğini, harita kartını ve kişisel sonuç tepkilerini kapsar.

Godot'un Movie Maker çıkışıyla yaklaşık 10 saniyelik stereo ses örneği kaydedildi. 48 kHz kayıtta ses bulunduğu ve hiçbir örneğin kırpılmadığı doğrulandı. Ses sekmesi de çizdirilerek kontrol edildi.

Windows'ta test çıktısının satır sonları nedeniyle bütün başarılı testlerin başarısız sayılması da düzeltildi. Test çalıştırıcısı artık motor hatalarını da başarısız sayar.

Ayarlar, duraklatma, orman, sonuç ve harita konuşması Godot ile çizdirilerek görsel olarak kontrol edildi. Denemeler ayrı bir kullanıcı veri klasöründe yapıldı; oyuncunun mevcut kaydı kullanılmadı.

## Kalan içerik işleri

Bu paket mevcut oynanabilir dikey dilimi düzeltir. Uzun vadeli oyun sonu döngüsü, XP/yetenek ağacı, hızar/sipariş/fidanlık sistemleri, çevrimdışı ilerleme ve Steam entegrasyonu hâlâ sonraki geliştirme işleridir. Ekonomi bot ölçümünden sonra insan oyun testiyle yeniden değerlendirilebilir.
