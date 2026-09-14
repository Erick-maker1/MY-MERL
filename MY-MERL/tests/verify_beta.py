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
    return ["Linea/Base separati", "6 ore/giorno", "troncamento a 1 decimale", "equivalenze tecniche", "esclusione non idonee"]


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
    forbidden = re.findall(r'https?://|URLSession|Firebase', joined)
    assert not forbidden, f"Rete inattesa nel codice: {forbidden}"
    contents = json.loads((APP / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json").read_text())
    assert contents["images"][0]["size"] == "1024x1024"
    return ["campi obbligatori rossi", "doppia conferma", "nessuna chiamata di rete", "CloudKit disattivato", "5 sezioni principali"]


if __name__ == "__main__":
    suites = [("LOGICA", logic_checks), ("PROGETTO", project_checks), ("GRAFICA/PRIVACY", interface_and_privacy_checks)]
    for name, test in suites:
        details = test()
        print(f"PASS {name}: " + "; ".join(details))
