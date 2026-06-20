# Richiesta inserita in chat per creare un file con timeline

Sono passati alcuni giorni e sto facendo fatica a ricostruire con precisione il lavoro che dobbiamo completare. Nei miei appunti ho trovato solo alcune note sparse.

Sono riuscito a sistemare tutte le foto; mi restano da correggere i video. Tuttavia, analizzandoli meglio, mi sto rendendo conto che gli orari associati ai video non mi convincono del tutto.

Per semplificare il lavoro, stavo valutando un approccio diverso almeno per foto e video Canon. Poiché entrambi i tipi di file utilizzano una numerazione progressiva e consecutiva, potremmo sfruttare quel numero come riferimento temporale per ricostruire correttamente la sequenza cronologica tra foto e video.

L'idea sarebbe di salvare in un tag/campo personalizzato esclusivamente la parte numerica del nome file, eliminando quindi il prefisso (`IMG_` o `MVI_`) e l'estensione. In questo modo potremmo ordinare facilmente tutti i file e verificare la corretta sequenza temporale prima di intervenire sui timestamp dei video.

Cosa ne pensi di questo approccio?

Prima di definire i passaggi operativi, però, vorrei ripartire dalla suddivisione dei file presenti in `~/Cina`. Come avevamo già fatto per la correzione delle foto, preferirei generare dei file lista separati per ciascuna categoria.

Ricordo che in una tua precedente risposta avevi suggerito di creare i seguenti file:

* `android_videos.txt`
* `canon_videos.txt`
* `canon_photos.txt`
* `iphone_media.txt`

Puoi fornirmi i comandi più rapidi ed efficienti per generare questi file lista?

---

## Risposta GPT

Penso che l'idea sia ottima.

Nel caso specifico della tua Canon G7 X Mark III, il numero progressivo del file è spesso più affidabile dei timestamp video quando si sono verificati problemi di fuso orario, conversioni o metadata QuickTime.

Esempio:

```text
IMG_1234.JPG
IMG_1235.JPG
MVI_1236.MP4
IMG_1237.JPG
IMG_1238.JPG
```

La sequenza reale degli eventi è quasi certamente:

```text
1234
1235
1236
1237
1238
```

indipendentemente da eventuali errori nei timestamp dei video.

Ti suggerisco quindi di:

1. Generare le liste separate.
2. Verificare la sequenza Canon usando il numero progressivo.
3. Solo dopo decidere se correggere i timestamp dei video Canon.
4. Lasciare Android come caso separato.

È un approccio molto più sicuro rispetto a modificare subito le date.

## Generazione delle liste

Assumo:

* Linux / WSL Ubuntu
* archivio in `~/Cina`

### 1. Foto Canon

Le Canon utilizzano normalmente `IMG_`.

```bash
find ~/Cina -type f \
-name 'IMG_*.JPG' \
| sort > canon_photos.txt
```

Verifica:

```bash
wc -l canon_photos.txt
```

---

### 2. Video Canon

Le Canon utilizzano normalmente `MVI_`.

```bash
find ~/Cina -type f \
-name 'MVI_*.MP4' \
| sort > canon_videos.txt
```

Verifica:

```bash
wc -l canon_videos.txt
```

---

### 3. Video Android

Per Android conviene usare ExifTool e identificare il produttore dal metadata, perché i nomi possono essere molto vari:

Prima verifica alcuni file:

```bash
exiftool -Make -Model ~/Cina/* 2>/dev/null | head -50
```

Se i video provengono dal Galaxy Note 10 Ultra dovresti vedere qualcosa simile:

```text
Make  : samsung
Model : SM-N975F
```

Poi:

```bash
exiftool \
-if '$Make =~ /samsung/i' \
-r -ext mp4 \
-p '$FilePath' \
~/Cina > android_videos.txt
```

---

### 4. Media iPhone

Se presenti:

```bash
exiftool \
-if '$Make =~ /apple/i' \
-r \
-ext jpg \
-ext jpeg \
-ext heic \
-ext mov \
-ext mp4 \
-p '$FilePath' \
~/Cina > iphone_media.txt
```

---

## Soluzione più robusta

Prima di eseguire qualsiasi modifica, ti consiglio di generare anche una lista completa con i dati che useremo per l'analisi:

```bash
exiftool -r \
-FileName \
-DateTimeOriginal \
-CreateDate \
-QuickTime:CreateDate \
-Make \
-Model \
-SamsungModel \
-ext jpg \
-ext mp4 \
-T \
~/Cina > media_inventory.tsv
```

Questo file diventa il punto di partenza per ricostruire tutto il lavoro fatto finora.

Una volta ottenute le liste, il passo successivo che farei è estrarre il numero progressivo dai file Canon (`1234`, `1235`, `1236`, ecc.) e salvarlo in un campo XMP dedicato. In questo modo avresti una chiave di ordinamento indipendente dai timestamp e potremmo verificare con precisione se i video Canon sono effettivamente fuori sequenza prima di toccare qualunque data.

---

## File creati possiamo passare allo step successivo ordinare i media della Canon utilizzando la secuenza numerica del nome file

Ottimo. In questo caso hai sfruttato una caratteristica molto utile del tuo archivio.

Se hai verificato che:

```text
Android -> *.mp4
Canon   -> *.MP4
```

allora il comando è corretto e soprattutto molto più veloce di qualsiasi filtro ExifTool.

A questo punto hai ricostruito una base di lavoro pulita:

```text
android_videos.txt
canon_videos.txt
canon_photos.txt
iphone_media.txt
```

e ti consiglio di conservarli perché potrebbero servirti più volte durante l'analisi.

## Passo successivo che farei

Prima di correggere qualsiasi timestamp dei video Canon o Android, creerei una chiave di ordinamento indipendente dalle date.

La tua idea di usare il numero progressivo Canon è molto valida.

Esempio:

```text
IMG_4321.JPG
IMG_4322.JPG
MVI_4323.MP4
IMG_4324.JPG
```

Il numero:

```text
4321
4322
4323
4324
```

rappresenta la sequenza reale di acquisizione.

Quindi prima di toccare le date potremmo salvare quel valore in un tag XMP dedicato.

Ad esempio:

```text
XMP:Identifier
```

oppure

```text
XMP:Label
```

oppure

```text
XMP:UserComment
```

se non lo stai già usando per altro.

## Verifica preliminare (consigliata)

Per capire se la sequenza Canon è coerente:

```bash
exiftool \
-T \
-FileName \
-DateTimeOriginal \
-QuickTime:CreateDate \
-@ canon_photos.txt \
-@ canon_videos.txt
```

Probabilmente dovremo eseguirlo separatamente per foto e video perché alcuni tag non esistono su entrambi i tipi di file.

## Quello che farei adesso

Prima ancora di scrivere metadata, estrarrei semplicemente il numero progressivo Canon in un report.

Ad esempio:

```bash
awk -F'[/_.]' '
{
    print $(NF-1)
}' canon_photos.txt | head
```

e

```bash
awk -F'[/_.]' '
{
    print $(NF-1)
}' canon_videos.txt | head
```

per verificare che il numero sia effettivamente quello che ci aspettiamo.

---

Verificare che Canon non abbia mai riutilizzato lo stesso numero tra foto e video.

Ad esempio sarebbe un problema se esistessero entrambi:

```text
IMG_1234.JPG
MVI_1234.MP4
```

In quel caso il numero non sarebbe una chiave univoca.

## Verifica non distruttiva

Genera l'elenco dei numeri delle foto:

```bash
awk -F'[/_.]' '
{
    print $(NF-1)
}' canon_photos.txt | sort -n > canon_photo_numbers.txt
```

Genera l'elenco dei numeri dei video:

```bash
awk -F'[/_.]' '
{
    print $(NF-1)
}' canon_videos.txt | sort -n > canon_video_numbers.txt
```

Verifica eventuali numeri presenti in entrambe le liste:

```bash
comm -12 \
canon_photo_numbers.txt \
canon_video_numbers.txt
```

## Interpretazione

### Nessun output

Ottimo.

Significa che:

```text
IMG_1234.JPG
IMG_1235.JPG
MVI_1236.MP4
IMG_1237.JPG
```

usa una numerazione globale unica.

In questo caso il numero progressivo può essere utilizzato come chiave cronologica affidabile.

### Output presente

Ad esempio:

```text
1234
5678
```

significherebbe che esistono sia:

```text
IMG_1234.JPG
MVI_1234.MP4
```

e quindi il numero non è sufficiente da solo.

## Verifica ancora più utile

Ti suggerisco anche di contare quanti numeri unici esistono.

Foto:

```bash
wc -l canon_photo_numbers.txt
```

Video:

```bash
wc -l canon_video_numbers.txt
```

Totale unione:

```bash
cat \
canon_photo_numbers.txt \
canon_video_numbers.txt \
| sort -n | uniq | wc -l
```

Se:

```text
foto + video = numeri unici
```

allora non esiste alcuna sovrapposizione.

Esempio:

```text
Foto  : 4120
Video : 180
Totale: 4300
```

e

```text
Unici : 4300
```

=> nessun duplicato.

---

Una volta verificata l'assenza di duplicati, il passo successivo sarà costruire una timeline Canon completa:

```text
Numero progressivo
Nome file
Tipo (foto/video)
Timestamp originale
```

e da lì individuare immediatamente eventuali video fuori sequenza senza modificare ancora nessun metadata. È il modo più sicuro per riprendere il lavoro dopo alcuni giorni e ricostruire con precisione ciò che era stato fatto.

## Richiesta successiva da parte dell'utente come segue

Procediamo con la creazione del campo personalizzato. Utilizzerei `XMP:Identifier`, poiché `XMP:UserComment` è già stato impiegato per memorizzare la data che dovremo successivamente verificare e correggere.

L'obiettivo è salvare in `XMP:Identifier` il numero progressivo estratto dal nome del file. Questo campo mi sarà utile anche all'interno di ExifToolGUI, dove potrò aggiungere una colonna dedicata e ordinare tutti i media in base a tale valore, ottenendo una vista unificata e una sequenza coerente tra foto e video.

Mi sembra la scelta migliore.

`XMP:Identifier` è adatto allo scopo e soprattutto ti permette di:

* lasciare intatto `XMP:UserComment`
* visualizzare facilmente il valore in ExifToolGUI
* ordinare foto e video insieme
* mantenere una chiave indipendente dai timestamp
* evitare di toccare metadata originali Canon

## Prima verifica (non distruttiva)

Ti consiglio di provare su un solo file foto e un solo file video.

Foto:

```bash
exiftool \
-p '$FileName -> ${FileName;s/\.[^.]+$//;s/^(IMG_|MVI_)//}' \
IMG_1234.JPG
```

Video:

```bash
exiftool \
-p '$FileName -> ${FileName;s/\.[^.]+$//;s/^(IMG_|MVI_)//}' \
MVI_1235.MP4
```

Dovresti ottenere:

```text
IMG_1234.JPG -> 1234
MVI_1235.MP4 -> 1235
```

---

## Backup consigliato

Ottima idea. Per modifiche ai metadata con ExifTool, il backup professionale e leggero è un **file ARG di rollback**.

Ti permette di:

* salvare solo i metadata che verranno modificati
* occupare pochi KB o MB
* ripristinare in pochi secondi
* evitare copie di JPG e MP4 sul NAS

## Soluzione consigliata

Prima di scrivere `XMP:Identifier`, esporta il valore attuale di quel tag.

Nel tuo caso il tag probabilmente non esiste ancora, ma il rollback sarà comunque possibile.

### Backup dei metadata

Foto Canon:

```bash
exiftool \
-j \
-FileName \
-XMP:Identifier \
-@ canon_photos.txt \
> canon_photos_identifier_backup.json
```

Video Canon:

```bash
exiftool \
-j \
-FileName \
-XMP:Identifier \
-@ canon_videos.txt \
> canon_videos_identifier_backup.json
```

Questa soluzione è utile per audit e verifica.

---

## Backup con rollback automatico ExifTool (consigliato)

Molto meglio creare direttamente un file ARG.

Foto:

```bash
exiftool \
-args \
-G1 \
-XMP:Identifier \
-@ canon_photos.txt \
> rollback_canon_photos_identifier.args
```

Video:

```bash
exiftool \
-args \
-G1 \
-XMP:Identifier \
-@ canon_videos.txt \
> rollback_canon_videos_identifier.args
```

Se vuoi puoi unirli:

```bash
cat \
rollback_canon_photos_identifier.args \
rollback_canon_videos_identifier.args \
> rollback_identifier.args
```

---

## Verifica del backup

Controlla che il file sia stato creato:

```bash
ls -lh rollback_identifier.args
```

Se il tag non esiste ancora vedrai righe del tipo:

```text
-XMP:Identifier=
```

che è corretto.

---

## Rollback

Se domani vuoi annullare tutto:

```bash
exiftool \
-overwrite_original \
-@ rollback_identifier.args \
-@ canon_photos.txt \
-@ canon_videos.txt
```

---

## Ancora meglio per il tuo caso

Poiché stai aggiungendo **un solo tag**, il rollback più semplice è addirittura:

```bash
exiftool \
-overwrite_original \
-XMP:Identifier= \
-@ canon_photos.txt \
-@ canon_videos.txt
```

Questo elimina completamente il campo da tutti i file.

Per questa specifica operazione è il metodo che adotterei io, perché:

* stiamo aggiungendo un nuovo tag
* non stiamo modificando tag esistenti
* il rollback è banale
* non serve salvare centinaia di MB di backup

Quindi procederei direttamente con:

1. Verifica finale su qualche file.
2. Scrittura di `XMP:Identifier`.
3. Se qualcosa non convince:

```bash
exiftool \
-overwrite_original \
-XMP:Identifier= \
-@ canon_photos.txt \
-@ canon_videos.txt
```

e torni esattamente alla situazione attuale.

---

## Scrittura del valore in XMP:Identifier

### Test su un solo file

Foto:

```bash
exiftool \
-overwrite_original \
'-XMP:Identifier<${FileName;s/\.[^.]+$//;s/^(IMG_|MVI_)//}' \
IMG_1234.JPG
```

Verifica:

```bash
exiftool -XMP:Identifier IMG_1234.JPG
```

Output atteso:

```text
Identifier : 1234
```

---

Perfetto. Se hai già verificato che `XMP:Identifier` non è presente nei file, il rollback è semplicissimo:

```bash
exiftool \
-overwrite_original \
-XMP:Identifier= \
-@ canon_photos.txt \
-@ canon_videos.txt
```

Quindi non farei alcun backup preventivo.

### 1. Test finale su un singolo file

Foto:

```bash
exiftool \
-overwrite_original \
'-XMP:Identifier<${FileName;s/\.[^.]+$//;s/^(IMG_|MVI_)//}' \
IMG_7843.JPG
```

Verifica:

```bash
exiftool \
-FileName \
-XMP:Identifier \
IMG_7843.JPG
```

Video:

```bash
exiftool \
-overwrite_original \
'-XMP:Identifier<${FileName;s/\.[^.]+$//;s/^(IMG_|MVI_)//}' \
MVI_7841.MP4
```

Verifica:

```bash
exiftool \
-FileName \
-XMP:Identifier \
MVI_7841.MP4
```

---

### 2. Aggiornamento massivo

Per evitare che eventuali warning minori interrompano o sporchino l'output, puoi usare:

```bash
-api IgnoreMinorErrors=1
```

Comando completo:

```bash
exiftool \
-api IgnoreMinorErrors=1 \
-overwrite_original \
'-XMP:Identifier<${FileName;s/\.[^.]+$//;s/^(IMG_|MVI_)//}' \
-@ canon_photos.txt \
-@ canon_videos.txt
```

Atteso:

```text
N image files updated
M video files updated
```

---

### 3. Verifica a campione

Foto:

```bash
exiftool \
-FileName \
-XMP:Identifier \
-@ canon_photos.txt | head -20
```

Video:

```bash
exiftool \
-FileName \
-XMP:Identifier \
-@ canon_videos.txt | head -20
```

Dovresti vedere qualcosa del tipo:

```text
File Name  : IMG_7843.JPG
Identifier : 7843

File Name  : MVI_7841.MP4
Identifier : 7841
```

---

### 4. Verifica globale

Per controllare che tutti i file Canon abbiano ricevuto il campo:

```bash
exiftool \
-if 'not $XMP:Identifier' \
-FileName \
-@ canon_photos.txt \
-@ canon_videos.txt
```

Se il comando non produce output, significa che tutti i file hanno correttamente `XMP:Identifier`.

---

### 5. Preparazione della timeline Canon

Una volta completato l'aggiornamento, genererei subito un report di lavoro:

```bash
exiftool \
-T \
-FileName \
-XMP:Identifier \
-DateTimeOriginal \
-QuickTime:CreateDate \
-XMP:UserComment \
-@ canon_photos.txt \
-@ canon_videos.txt \
| sort -k2,2n > canon_timeline.tsv
```

Questo sarà il file che useremo per verificare se i timestamp dei video Canon sono coerenti con la sequenza reale determinata dal numero progressivo.

## Determinare l'offset da usare come shift time

Per determinare quale sia l'offset da utilizzare come Shit Time andermo a cercare il video nel file `canon_timeline.tsv` tramite il comadno `grep`

### 1. Impostiamo una variabile per memorizzare il numero sequenziale che andremo a cercare e lavoriamo su una copia di test del file video

```bash
num_media="7514"
cp MVI_${num_media}.MP4 MVI_${num_media}.TEST.MP4
grep -B 2 -A 2 ${num_media} canon_timeline.tsv
```

L'output sarà:

```text
fabrizio@NirvanaHome:~/Cina$ grep -B 2 -A 2 ${num_media} canon_timeline.tsv
IMG_7510.JPG    7510    2026:04:04 09:55:50     -       2026-04-04T09:55:50
MVI_7512.MP4    7512    2026:04:04 04:09:41     2026:04:04 02:09:42     -
MVI_*7514*.MP4    *7514*    2026:04:04 04:37:34     2026:04:04 02:37:36     2026-04-04T02:37:36
IMG_7516.JPG    7516    2026:04:04 10:50:58     -       2026-04-04T10:50:58
IMG_7519.JPG    7519    2026:04:04 11:48:57     -       2026-04-04T11:48:57
```

### 2. Verifica iniziale

```bash
exiftool -time:all -a -G1 -s MVI_{num_media}.TEST.MP4 | tee MVI_{num_media}.before.txt
```

L'output sarà:

```text
[System]        FileModifyDate                  : 2026:06:06 18:35:08+02:00
[System]        FileAccessDate                  : 2026:06:06 18:35:12+02:00
[System]        FileInodeChangeDate             : 2026:06:06 18:35:08+02:00
[IFD0]          ModifyDate                      : 2026:04:04 04:37:34
[ExifIFD]       DateTimeOriginal                : 2026:04:04 04:37:34
[ExifIFD]       CreateDate                      : 2026:04:04 04:37:34
[ExifIFD]       OffsetTime                      : +02:00
[ExifIFD]       OffsetTimeOriginal              : +02:00
[ExifIFD]       OffsetTimeDigitized             : +02:00
[Canon]         TimeZone                        : +02:00
[Canon]         TimeZoneCity                    : Paris
[Canon]         DaylightSavings                 : On
[ExifIFD]       SubSecTime                      : 85
[ExifIFD]       SubSecTimeOriginal              : 85
[ExifIFD]       SubSecTimeDigitized             : 85
[QuickTime]     CreateDate                      : 2026:04:04 02:37:36
[QuickTime]     ModifyDate                      : 2026:04:04 02:37:36
[Track1]        TrackCreateDate                 : 2026:04:04 02:37:36
[Track1]        TrackModifyDate                 : 2026:04:04 02:37:36
[Track1]        MediaCreateDate                 : 2026:04:04 02:37:36
[Track1]        MediaModifyDate                 : 2026:04:04 02:37:36
[Composite]     SubSecCreateDate                : 2026:04:04 04:37:34.85+02:00
[Composite]     SubSecDateTimeOriginal          : 2026:04:04 04:37:34.85+02:00
[Composite]     SubSecModifyDate                : 2026:04:04 04:37:34.85+02:00
```

---

### 3. Applicazione dello shift di +8 ore ai soli tag EXIF

Nel tuo caso:

```text
02:37:36 -> 10:37:36
```

Verifica il valore attuale:

```bash
exiftool -G1 -a -s \
-QuickTime:CreateDate \
MVI_${num_media}.TEST.MP4
```

Poi prova:

```bash
exiftool \
"-QuickTime:CreateDate+=0:0:0 08:00:00" \
MVI_${num_media}.TEST.MP4
```

Non modifichiamo:

```text
TrackCreateDate
MediaCreateDate
Canon:TimeZone
Canon:TimeZoneCity
```

---

### 4. Verifica dopo la modifica

```bash
exiftool -G1 -a -s \
-ExifIFD:DateTimeOriginal \
-ExifIFD:CreateDate \
-ExifIFD:OffsetTimeOriginal \
-QuickTime:CreateDate \
-Track1:MediaCreateDate \
-Track2:MediaCreateDate \
MVI_${num_media}.TEST.MP4
```

Dovresti ottenere qualcosa di simile:

```text
[ExifIFD]       DateTimeOriginal                : 2026:04:04 04:37:34
[ExifIFD]       CreateDate                      : 2026:04:04 04:37:34
[ExifIFD]       OffsetTimeOriginal              : +02:00

[QuickTime]     CreateDate                      : 2026:04:04 10:37:36

[Track1]        MediaCreateDate                 : 2026:04:04 02:37:36
```

## Perché partire da QuickTime:CreateDate

Perché dai metadati che hai mostrato è il primo candidato serio:

```text
[QuickTime] CreateDate
```

e non appartiene ai blocchi Canon proprietari.

Inoltre:

```text
TrackCreateDate
MediaCreateDate
```

sono spesso derivati dalle strutture interne delle tracce e non sempre risultano modificabili individualmente.

## La mia ipotesi attuale

Dopo tutte le prove fatte, credo che la strategia migliore sarà:

1. Lasciare invariati:

   ```text
   Canon:TimeZone
   Canon:TimeZoneCity
   TrackCreateDate
   MediaCreateDate
   ```

2. Individuare uno o due tag QuickTime realmente scrivibili.

3. Verificare quale di questi viene usato da:

   * Google Photos
   * QNAP Photo Station 5
   * digiKam

4. Correggere soltanto quei tag tramite shift `+=`.

Prima di progettare la procedura batch con `-@`, il prossimo passo è capire una cosa molto semplice:

**`QuickTime:CreateDate` è realmente scrivibile oppure no?**

Se mi mostri l'output di:

```bash
exiftool \
"-QuickTime:CreateDate+=0:0:0 08:00:00" \
MVI_${num_media}.TEST.MP4
```

possiamo stabilirlo con certezza.

---

## Risposta da parte mia

Nel test ho applicato uno shift di `+8 ore`, poiché il tag `QuickTime:CreateDate` risulta memorizzato in UTC. In questo modo il timestamp viene convertito correttamente nell'orario locale di registrazione senza alterare arbitrariamente la data e l'ora originali.

```bash
exiftool -v3 "-QuickTime:CreateDate+=0:0:0 08:00:00" MVI_${num_media}.TEST.MP4
```

```text
Shifting QuickTime:CreateDate if tag exists
======== MVI_7285.TEST.MP4
Rewriting MVI_7285.TEST.MP4...
  FileType = MP4
  FileTypeExtension = MP4
  MIMEType = video/mp4
  Editing tags in: ItemList MOV Meta Movie QuickTime UserData 
  Creating tags in: 
  Rewriting Movie
  Rewriting UUID-Canon
  Rewriting CanonCNTH
    [nothing changed in CanonCNTH]
    [nothing changed in UUID-Canon]
  Rewriting UserData
    [nothing changed in UserData]
  Rewriting MovieHeader
    - MovieHeader:CreateDate = '3857938992'
    + MovieHeader:CreateDate = '3857967792'
  Rewriting Track
  Rewriting TrackHeader
    [nothing changed in TrackHeader]
  Rewriting Media
  Rewriting MediaHeader
    [nothing changed in MediaHeader]
  Rewriting MediaInfo
  Rewriting DataInfo
  Rewriting DataRef
    [nothing changed in DataRef]
    [nothing changed in DataInfo]
  Rewriting SampleTable
    [nothing changed in SampleTable]
    [nothing changed in MediaInfo]
    [nothing changed in Media]
    [nothing changed in Track]
  Rewriting Track
  Rewriting TrackHeader
    [nothing changed in TrackHeader]
  Rewriting Media
  Rewriting MediaHeader
    [nothing changed in MediaHeader]
  Rewriting MediaInfo
  Rewriting DataInfo
  Rewriting DataRef
    [nothing changed in DataRef]
    [nothing changed in DataInfo]
  Rewriting SampleTable
    [nothing changed in SampleTable]
    [nothing changed in MediaInfo]
    [nothing changed in Media]
    [nothing changed in Track]
  Rewriting XMP
    [nothing changed in XMP]
    1 image files updated

fabrizio@NirvanaHome:~/Cina$ exiftool -G1 -a -s -QuickTime:CreateDate MVI_7285.TEST.MP4
[QuickTime]     CreateDate                      : 2026:04:02 09:43:12
```

---

Ottimo. Questo test ci ha dato finalmente una risposta concreta.

Dal log si vede chiaramente che il comando ha modificato realmente il file. ExifTool ha aggiornato il valore interno del `MovieHeader:CreateDate` e ha concluso con:

```text
1 image files updated
```

invece del precedente:

```text
Nothing changed
```

Inoltre la verifica finale conferma il risultato:

```text
[QuickTime] CreateDate : 2026:04:02 09:43:12
```



## Conclusioni tecniche

Possiamo affermare con buona sicurezza che:

### Scrivibile

```text
QuickTime:CreateDate
```

### Non dimostrati scrivibili

```text
ExifIFD:DateTimeOriginal
ExifIFD:CreateDate
```

Nei video Canon MP4.

### Non toccati dal test

```text
Track1:TrackCreateDate
Track1:MediaCreateDate
Track2:TrackCreateDate
Track2:MediaCreateDate
```

### Non toccati

```text
Canon:TimeZone
Canon:TimeZoneCity
```

---

## Aspetto molto interessante

Nel log compare:

```text
Editing tags in:
ItemList MOV Meta Movie QuickTime UserData
```

e successivamente:

```text
MovieHeader:CreateDate
```

Questo suggerisce che il tag visualizzato come:

```text
QuickTime:CreateDate
```

non è un semplice campo derivato ma è effettivamente mappato ad una struttura QuickTime modificabile.



---

## Perché preferisco anche io lo shift

Nel tuo scenario è la scelta migliore.

Invece di fare:

```bash
-QuickTime:CreateDate="2026:04:02 09:43:12"
```

fai:

```bash
-QuickTime:CreateDate+=0:0:0 06:00:00
```

oppure:

```bash
-QuickTime:CreateDate+=0:0:0 08:00:00
```

e ottieni:

* procedura ripetibile;
* nessun errore di digitazione;
* applicabile in batch;
* perfetta integrazione con file `-@`;
* conservazione della sequenza temporale relativa.

---

## Prossimo test che farei

A questo punto non toccherei ancora:

```text
TrackCreateDate
MediaCreateDate
```

Prima importerei questo file modificato in:

* Google Photos
* QNAP Photo Station 5
* digiKam

e verificherei quale orario compare.

### Se compare

```text
2026:04:02 09:43:12
```

abbiamo già individuato un tag utilizzato dal catalogatore.

### Se continua a comparire

```text
2026:04:02 03:43:12
```

oppure

```text
2026:04:02 01:43:12
```

allora il software sta leggendo un altro tag e passeremo al test successivo.

---

## Stato attuale della strategia

Per ora la procedura più prudente è:

1. Non modificare i tag Canon.
2. Non modificare i tag `Track*` e `Media*`.
3. Usare come riferimento le fotografie corrette.
4. Calcolare l'offset necessario per ogni gruppo di video.
5. Applicare lo shift a:

```text
QuickTime:CreateDate
```

6. Verificare il comportamento di:

   * Google Photos
   * QNAP Photo Station 5
   * digiKam

Solo dopo questi test conviene decidere se aggiornare anche altri tag oppure se `QuickTime:CreateDate` da solo è sufficiente per pilotare la timeline dei catalogatori che utilizzi.
