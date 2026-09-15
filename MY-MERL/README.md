# MY MERL 1.0.2 — iPhone offline

Applicazione personale e offline per registrare attività MERL e generare il modello ENAC.

## Funzioni incluse

- database SwiftData locale, senza server e senza CloudKit;
- inserimento rapido con campi obbligatori evidenziati;
- rubriche per sedi Base/Linea, aeromobili, marche e supervisori;
- riferimenti AMM, EMM o altro separati per tipo di aeromobile;
- ATA proposto dal codice ma sempre modificabile;
- classificazione automatica in tutte le sezioni ENAC 1–5 che contengono lo stesso ATA (per esempio ATA 71 nelle sezioni 4 e 5);
- attività `B-` o `L-` automatica in base alla sede;
- registro ricercabile e cancellazione con doppia conferma;
- calcolo giornate Linea/Base su 6 ore, visualizzato con un decimale troncato;
- conteggio delle tipologie tecniche tramite gruppo di equivalenza;
- PDF con pagine MERL da 8 righe e riepiloghi ufficiali ENAC;
- registro CSV compatibile con Excel;
- backup completo esportabile e importabile con doppia conferma.

## Privacy

L'app non contiene chiamate di rete. Tutti i dati operativi sono nel contenitore locale iOS. La compilazione su GitHub contiene solo il codice sorgente e il modello ENAC vuoto.

La build 120 mostra `v1.0.2 · 120` in Nuova attività e `MY MERL 1.0.2 · 120` in Rubriche, così la versione installata è verificabile direttamente dall'iPhone.

## Build gratuita

Il workflow `.github/workflows/build-ios.yml` compila un IPA non firmato. AltStore Classic lo firma con l'Apple Account personale durante l'installazione.

## Verifica locale

```bash
python3 tests/verify_beta.py
```

Il controllo definitivo di compilazione deve essere eseguito dal workflow macOS; il controllo visivo finale deve essere svolto sull'iPhone 15 Pro.
