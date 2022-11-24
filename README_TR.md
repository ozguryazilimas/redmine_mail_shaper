
# Mail Shaper

Redmine eposta sistemine yeni yetenekler ekler.

Bu daldaki sürümler Redmine 4.x ile uyumludur, Redmine 3.x serisi için redmine3 dalını inceleyiniz.

Redmine 4.x ve 5.x uyumludur.

## Özellikleri

1. Wiki sayfası güncellemeleri ve yeni wiki sayfası içeriği email yoluyla alınır.
2. Eğer iş bir alt işse, üst iş konusu da alt işle beraber iletilir.
3. Wiki sayfasındaki değişiklikler e-posta yoluyla alındığı zaman yapılan tüm değişiklikleri gösteren uzun bir e-postayı engellemek için satır sayısı limitlenir.
4. Zaman kaydı girdileri için e-posta yoluyla kullanıcılara e-posta gidebilir.
5. İş kaydındaki tek bir değişiklik için örneğin atanan kısmı değişikliği için e-posta alımı engellenebilir.

## Ayarlar

* Eklenti ayarlarına yönetici hesabı ile /administration/plugins/redmine_mail_shaper adresinden ulaşılabilir.

## Kullanımı

* Issue parent subject: Aktif edilirse, iş bir alt iş ise gelen e-postada üst işin konusu da yazar.
* Changes on wiki page updates: Wiki sayfasında yapılan güncellemeler için ile e-posta gelir.
* Content of new wiki pages: Yeni wiki sayfasının içeriği e-posta yoluyla iletilir.
* Number of lines around differences: Bu alana wiki sayfasında yapılan değişikliklerin kaç satır üstü ve kaç satır altı gösterileceği yazılır.
Örnek: Buraya 4 değeri girilirse wikide yapılan değişikliklerin 4 satır üstü ve 4 satır altı da e-posta ile gelir. E-postada, yapılan değişiklikler yeşil ile gösterilir.
* Maximum number of diff lines displayed: Wiki sayfasında yapılan dğeişiklikler çok fazla ise uzun bir e-postadan kaçınmak için buraya rakam yazarak limitlenebilir.
Örnek:
Bu alana 50 yazılır ise e-posta yoluyla e-postada 50 satır değişiklik gözükür.
* Time entries trigger email notification: Aktif edilirse zaman kaydı girdileri için e-posta iletilir.
* Time entries create issue journal: İş kaydında zaman girdilerinin yorum olarak gözükmesi istenirse aktif edilir.
* Spent time: İş kaydındaki tek değişik harcanan zaman girdisi ise ve e-posta ile alınmak istenirse seçilir.
* Files: İş kaydında tek değişik dosya eklenmesi ise ve bu e-posta ile alınmak istenirse seçilir.
* Attributes:  İş kaydında hangi alanda değişiklik yapıldığında e-posta alınmak istenmiyorsa o seçenek seçilir.
* Custom fields: Özel alanda yapılan tek değişiklik için e-posta alınmak istenmiyorsa bu seçenek seçilir.

## Lisans

Copyright (c) 2012, Onur Küçük. lisansı [GNU GPLv2](LICENSE)


