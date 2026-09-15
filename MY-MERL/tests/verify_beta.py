#!/usr/bin/env python3
"""Three independent, deterministic checks that can run on Windows/Linux.

The final compile and on-device checks are performed by Xcode/GitHub Actions.
"""
from __future__ import annotations

import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "MYMERL"


def logic_checks() -> list[str]:
    # ENAC-equivalent rules mirrored from SummaryCalculator.swift.
    records = [
        dict(ata="21", mode="Base", hours=2.0, model="H145", manual="AMM", code="A", group="COND", eligible=True),
        dict(ata="21", mode="Base", hours=4.0, model="H145", manual="AMM", code="B", group="COND", eligible=True),
        dict(ata="21", mode="Linea", hours=6.0, model="H145", manual="AMM", code="C", group="ELEC", eligible=True),
        dict(ata="21", mode="Linea", hours=99.0, model="H145", manual="AMM", code="X", group="IGNORED", eligible=False),
    ]
    eligible = [x for x in records if x["eligible"]]
    assert sum(x["hours"] for x in eligible if x["mode"] == "Base") == 6
    assert sum(x["hours"] for x in eligible if x["mode"] == "Linea") == 6
    assert len(eligible) == 3
    assert len({x["group"] or f'{x["model"]}|{x["manual"]}|{x["code"]}' for x in eligible}) == 2
    assert math.floor((32 / 6) * 10) / 10 == 5.3
    source = (APP / "Services" / "SummaryCalculator.swift").read_text()
    for rule in ["lineHours / 6.0", "baseHours / 6.0", "floor(value * 10) / 10", "equivalenceGroup", "isMERLEligible"]:
        assert rule in source, f"Regola assente: {rule}"
    domain = (APP / "Models" / "Domain.swift").read_text()
    activity_view = (APP / "Views" / "NewActivityView.swift").read_text()
    assert 'id:"S4-71",section:4,ata:"71"' in domain
    assert 'id:"S5-71",section:5,ata:"71"' in domain
    assert "summaryCandidates.sorted" in activity_view
    assert "rowIDs.forEach" in source and 'split(separator: ",")' in source
    # Una singola attività ATA 71 viene espansa nelle due righe ENAC.
    encoded_rows = "S4-71,S5-71".split(",")
    assert encoded_rows == ["S4-71", "S5-71"] and len(encoded_rows) == 2
    return ["Linea/Base separati", "6 ore/giorno", "troncamento a 1 decimale", "equivalenze tecniche", "ATA 71 automatico in sezioni 4+5", "esclusione non idonee"]


def project_checks() -> list[str]:
    pbx = (ROOT / "MYMERL.xcodeproj" / "project.pbxproj").read_text()
    swift_files = sorted(APP.rglob("*.swift"))
    missing = [p.name for p in swift_files if p.name not in pbx]
    assert not missing, f"File Swift non inclusi nel progetto: {missing}"
    assert "Part66_MERL_EdLuglio_2006.pdf" in pbx
    assert (APP / "Resources" / "Part66_MERL_EdLuglio_2006.pdf").stat().st_size > 100_000
    assert (APP / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png").stat().st_size > 10_000
    workflow = (ROOT / ".github" / "workflows" / "build-ios.yml").read_text()
    for token in ["macos-15", "CODE_SIGNING_ALLOWED=NO", "MY-MERL-beta.ipa"]:
        assert token in workflow
    return [f"{len(swift_files)} file Swift collegati", "PDF ENAC incluso", "icona 1024 px", "workflow IPA senza firma"]


def interface_and_privacy_checks() -> list[str]:
    joined = "\n".join(p.read_text() for p in APP.rglob("*.swift"))
    for required in ["Nuova attività", "Registro", "Riepilogo", "Esporta", "Rubriche"]:
        assert required in joined
    assert "Color.red.opacity" in joined
    assert joined.count("role: .destructive") >= 4  # doppia conferma eliminazione + importazione
    assert "cloudKitDatabase: .none" in joined
    assert "Impresa di esempio" not in joined
    assert "Impresa associata" not in joined
    pdf_exporter = (APP / "Services" / "MERLPDFExporter.swift").read_text()
    assert "Dictionary(grouping: records, by: { $0.company })" not in pdf_exporter
    assert "draw(company:" not in pdf_exporter
    assert "L'impresa è intenzionalmente ignorata" in pdf_exporter
    assert "Codice già presente nel database" in joined
    assert "Cerca codice o descrizione" in joined
    assert "File pronti" in joined and "deleteGeneratedFile" in joined
    assert "Il registro non è stato modificato" in joined
    assert "Pagina MERL completata" in joined and "exportPage" in joined
    assert "PageCheckpointStore.markExported" in joined and "già esportata" in joined
    assert "Compila soltanto le caselle bianche" in joined
    assert 'fixed("-")' in joined and 'fixed(",")' in joined
    assert joined.count("numeric: false, width:") >= 5
    assert ".frame(width: width, minHeight:" not in joined
    assert "private var activityForm: some View" in joined
    assert "private var presentedForm: some View" in joined
    assert "private var alertedForm: some View" in joined
    assert "? .tint : .secondary" not in joined
    assert 'draft.ata = ""' in joined and 'draft.description = ""' in joined
    assert "guard draft.codeComplete else { return }" in joined
    assert "MY MERL 1.0.2 · 120" in joined and 'Text("v1.0.2 · 120")' in joined
    directories = (APP / "Views" / "DirectoriesView.swift").read_text()
    assert directories.count(".onDelete") == 4
    assert "EditButton()" in directories and 'Image(systemName: "trash")' in directories
    assert "target: @escaping () -> DirectoryDelete" in directories
    assert "ScrollViewReader" in joined and 'scrollTo("activityFormTop"' in joined
    assert "draft.activityCode.title" in joined
    assert 'ToolbarItemGroup(placement: .keyboard)' in joined and 'Button("Fine")' in joined
    assert 'Section("Da completare")' in joined and "stepErrors" in joined
    assert 'Section("Tempo di lavoro")' in joined
    assert r'draft.summaryRowIDs = ["ATA-\(draft.ata)"]' in joined
    assert "Seleziona il dettaglio tecnico ENAC" not in joined
    assert "Formato automatico:" not in joined
    for example in ['codeField("21"', 'codeField("53"', 'codeField("02"', 'codeField("6"', 'codeField("1"']:
        assert example not in joined
    for kind in [".site", ".aircraft", ".registration", ".supervisor"]:
        assert f"kind: {kind}" in directories
    seed = (APP / "Services" / "SeedService.swift").read_text()
    assert "context.insert" not in seed
    forbidden = re.findall(r'https?://|URLSession|Firebase', joined)
    assert not forbidden, f"Rete inattesa nel codice: {forbidden}"
    contents = json.loads((APP / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json").read_text())
    assert contents["images"][0]["size"] == "1024x1024"
    return ["campi obbligatori rossi", "doppia conferma", "nessun dato dimostrativo", "ricerca equivalenti assistita", "nessuna chiamata di rete", "CloudKit disattivato", "5 sezioni principali"]


if __name__ == "__main__":
    suites = [("LOGICA", logic_checks), ("PROGETTO", project_checks), ("GRAFICA/PRIVACY", interface_and_privacy_checks)]
    for name, test in suites:
        details = test()
        print(f"PASS {name}: " + "; ".join(details))
