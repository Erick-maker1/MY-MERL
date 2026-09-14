# Installare MY MERL gratuitamente su iPhone da Windows

## Parte A — ottenere il file IPA

1. Accedere a GitHub con un account gratuito.
2. Creare un repository **privato** chiamato `MY-MERL`.
3. Caricare il contenuto della cartella del progetto, mantenendo `.github/workflows/build-ios.yml`.
4. Aprire la scheda **Actions** del repository.
5. Se richiesto, abilitare i workflow.
6. Aprire **Build MY MERL beta** e premere **Run workflow**.
7. Attendere il segno di spunta verde.
8. Aprire l'esecuzione completata e scaricare l'artefatto `MY-MERL-beta`.
9. Estrarre lo ZIP: all'interno si trova `MY-MERL-beta.ipa`.

Il repository contiene il codice dell'app, non il database personale che verrà creato sull'iPhone.

## Parte B — installare AltStore Classic

1. Dal sito ufficiale AltStore scaricare **AltServer for Windows**.
2. Installare iTunes e iCloud dai collegamenti diretti Apple indicati nella guida AltStore; evitare le versioni Microsoft Store salvo procedura alternativa.
3. Installare AltServer e avviarlo come amministratore.
4. Collegare l'iPhone al PC via cavo, sbloccarlo e scegliere **Autorizza** quando richiesto.
5. Accedere a iTunes con il proprio Apple Account e attivare la sincronizzazione Wi‑Fi dell'iPhone.
6. Dall'icona AltServer nell'area di notifica scegliere **Install AltStore** e selezionare l'iPhone.
7. Inserire l'Apple Account. AltStore dichiara che le credenziali vengono inviate soltanto ad Apple.
8. Su iPhone aprire **Impostazioni > Generali > VPN e gestione dispositivo**, selezionare l'Apple Account e confermare **Autorizza**.
9. Aprire **Impostazioni > Privacy e sicurezza > Modalità sviluppatore**, attivarla e riavviare quando richiesto.

## Parte C — installare MY MERL

1. Trasferire `MY-MERL-beta.ipa` nell'app File dell'iPhone, per esempio tramite cavo, iCloud Drive personale o allegato a sé stessi.
2. Aprire AltStore sull'iPhone.
3. Nella sezione **My Apps** premere `+`.
4. Selezionare `MY-MERL-beta.ipa`.
5. Attendere la firma e l'installazione; comparirà l'icona **MY MERL**.
6. Aprire l'app e inserire una singola attività di prova.
7. Da **Esporta**, creare immediatamente un backup di prova e verificare che il file possa essere salvato nell'app File.

## Rinnovo gratuito ogni 7 giorni

1. Lasciare AltServer avviato sul PC.
2. Collegare iPhone e PC alla stessa rete Wi‑Fi.
3. Aprire AltStore almeno una volta alla settimana.
4. In **My Apps**, premere **Refresh All** prima della scadenza.

Il rinnovo aggiorna la firma e non deve cancellare il database. Prima di ogni aggiornamento beta è comunque consigliato esportare un backup MY MERL.
