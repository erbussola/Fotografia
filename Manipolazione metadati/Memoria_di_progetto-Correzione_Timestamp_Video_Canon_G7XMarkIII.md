# Memoria di Progetto – Correzione Timestamp Video Canon G7 X Mark III

## Obiettivo

Correggere i metadati temporali di circa 25 video MP4 registrati durante un viaggio in Cina affinché vengano posizionati correttamente nella timeline di Google Photos e degli altri catalogatori.

Le fotografie sono già state corrette e rappresentano il riferimento temporale affidabile.

---

## Contesto

Durante il viaggio la Canon G7 X Mark III è stata utilizzata con configurazioni errate del fuso orario:

* inizialmente impostata su Europa/Roma (UTC+2);
* successivamente modificata ma ancora errata;
* infine configurata correttamente.

Le foto sono state corrette con successo.

I video presentano invece timestamp incoerenti a causa della gestione dei metadati QuickTime.

---

## Attività completate

### Analisi metadati

Verificato che i video Canon contengono:

* ExifIFD:DateTimeOriginal
* ExifIFD:CreateDate
* OffsetTimeOriginal
* QuickTime:CreateDate
* TrackCreateDate
* MediaCreateDate
* Canon TimeZone
* Canon TimeZoneCity

---

### Tag Canon proprietari

Accertato che:

* ExifTool legge correttamente i tag Canon proprietari;
* non è in grado di scriverli;
* non è una strada percorribile.

Decisione:

* non utilizzare i tag Canon per la correzione.

---

### Tag EXIF nei video

Tentativo di modifica:

```bash
-ExifIFD:DateTimeOriginal
-ExifIFD:CreateDate
```

Risultato:

```text
Nothing changed
```

Conclusione:

* presenti in lettura;
* non modificabili nei file MP4 Canon testati.

---

### Keys:CreationDate (tested)

Creato e testato:

```text
Keys:CreationDate = 2026:04:04 10:37:36+08:00
```

Risultato:

* ignorato da Google Photos;
* ignorato da Photo Station 5.

Conclusione:

* non può essere considerato il tag primario per la timeline.

---

### QuickTime:CreateDate

Verificato che è scrivibile.

Test:

```bash
-QuickTime:CreateDate+=0:0:0 08:00:00
```

Risultato:

* modifica applicata correttamente;
* Google Photos reagisce al cambiamento.

Conclusione:

Google Photos utilizza principalmente:

```text
QuickTime:CreateDate
```

---

### TrackCreateDate / MediaCreateDate

Verificato che sono scrivibili.

Test:

```bash
-TrackCreateDate+=0:0:0 08:00:00
-MediaCreateDate+=0:0:0 08:00:00
```

Risultato:

Photo Station modifica immediatamente la data visualizzata.

Conclusione:

Photo Station 5 utilizza principalmente:

```text
TrackCreateDate
MediaCreateDate
```

---

### Configurazione NAS

Verifiche eseguite:

```bash
date
cat /etc/TZ
getcfg System "Time Zone"
```

Risultato:

* timezone corretto;
* DST attivo;
* NTP funzionante.

Conclusione:

il problema non è causato dalla configurazione del NAS.

---

## Decisioni tecniche

### Google Photos

Tag di riferimento:

```text
QuickTime:CreateDate
```

Comportamento:

* interpretato come UTC;
* convertito automaticamente nel timezone locale.

---

### Photo Station 5

Tag di riferimento:

```text
TrackCreateDate
MediaCreateDate
```

Comportamento:

* ignora ExifIFD:DateTimeOriginal;
* ignora Keys:CreationDate;
* utilizza i timestamp delle tracce video.

---

### Keys:CreationDate

Pur essendo il tag più corretto dal punto di vista teorico (contiene timezone esplicito), non viene utilizzato dai software testati.

Decisione:

* non considerarlo soluzione primaria.

---

## Problemi aperti

### digiKam

Non è stato ancora verificato quale tag utilizzi.

Da determinare se segue:

```text
QuickTime:CreateDate
```

oppure:

```text
TrackCreateDate
```

---

### Tag universale

Non è stato individuato un singolo tag utilizzato contemporaneamente da:

* Google Photos;
* Photo Station 5;
* Windows Explorer.

Probabile conclusione:

* non esiste un tag universale nei file MP4 Canon testati.

---

## Procedura prevista per i 25 video

### Determinazione offset

Utilizzare:

```text
canon_timeline.tsv
```

e confrontare ogni video con:

* foto precedente;
* foto successiva;
* numerazione progressiva Canon.

Calcolare:

```text
+6 ore
oppure
+8 ore
```

a seconda del periodo del viaggio.

---

### Correzione orientata a Google Photos

Applicare lo shift a:

```bash
-QuickTime:CreateDate+=0:0:0 HH:00:00
```

dove HH = 6 oppure 8.

---

## Possibile soluzione futura

Abbandonare Photo Station 5 per la consultazione remota.

Valutare:

* Immich su Raspberry Pi 4;
* accesso tramite Tailscale.

Preferenza attuale:

```text
Immich
```

per migliore gestione di video, timezone e timeline.

---

## Procedura operativa per futuri viaggi

Prima di partire:

1. verificare data;
2. verificare ora;
3. verificare timezone;
4. verificare città associata al timezone.

All'arrivo nel nuovo paese:

1. aggiornare il timezone della fotocamera;
2. non modificare soltanto l'ora.

Scatto di controllo:

1. fotografare lo smartphone con l'ora locale visibile;
2. registrare un breve video dello stesso schermo.

Questo crea un riferimento temporale certo per eventuali correzioni future.
