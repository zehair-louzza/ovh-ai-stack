"""Vérification non destructive du pack, puis découverte réelle dans Hermes."""
import argparse
import hashlib
import json
import os
import re
import shutil
import urllib.request
import uuid
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--files", action="store_true")
    parser.add_argument("--smoke", action="store_true")
    parser.add_argument("--cleanup-legacy", action="store_true")
    args = parser.parse_args()
    root = (Path("hermes/skills-blueseatra") if args.files
            else Path("/opt/blueseatra-skills"))
    paths = sorted(root.glob("blueseatra-*/SKILL.md"))
    if len(paths) != 25:
        raise SystemExit(f"Pack TCE incomplet : {len(paths)}/25")
    names = [p.parent.name for p in paths]
    for path in paths:
        text = path.read_text(encoding="utf-8")
        if not text.startswith("---\n") or f"name: {path.parent.name}\n" not in text:
            raise SystemExit(f"Frontmatter incorrect : {path.parent.name}")
    schemas = sorted(root.glob("blueseatra-tce-*/references/schema.json"))
    if {p.parent.parent.name for p in schemas} != {
        "blueseatra-tce-extraction", "blueseatra-tce-nomenclature",
        "blueseatra-tce-redaction", "blueseatra-tce-audit",
    }:
        raise SystemExit("Schémas TCE incomplets")
    for path in schemas:
        json.loads(path.read_text(encoding="utf-8"))
    h = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        if path.is_file() and path.relative_to(root).parts[0].startswith("blueseatra-"):
            h.update(path.relative_to(root).as_posix().encode())
            h.update(path.read_bytes())
    print(f"tce_v4 fichiers=25 schemas=4 sha256={h.hexdigest()}")
    if not args.files:
        obsolete = {"extraire-demande-travaux", "decrire-demande-travaux"}
        if args.cleanup_legacy:
            # Retrait autorisé de ces DEUX anciens skills uniquement. Les
            # éventuelles copies du volume sont archivées hors de l'index ;
            # mémoire et skills généraux ne sont jamais touchés.
            local_root = Path("/opt/data/skills")
            backup = Path("/opt/data/backups/tce-v4-legacy") / str(uuid.uuid4())
            for path in sorted(local_root.rglob("SKILL.md")):
                match = re.search(r"^name:\s*[\"']?([a-z0-9-]+)[\"']?\s*$",
                                  path.read_text(encoding="utf-8"), re.M)
                if not match or match.group(1) not in obsolete:
                    continue
                folder = path.parent
                if not folder.resolve().is_relative_to(local_root.resolve()) or folder.is_symlink():
                    raise SystemExit("Ancien skill en lien symbolique : retrait manuel requis")
                target = backup / folder.relative_to(local_root)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(folder), str(target))
                print("tce_v4 ancien_skill_archive=" + match.group(1))
        # API de découverte Hermes, aucun appel IA et aucun secret affiché.
        from tools.skills_tool import skills_list, skill_view
        catalog = skills_list()
        catalog = json.loads(catalog) if isinstance(catalog, str) else catalog
        discovered = {row["name"] for row in catalog.get("skills", [])}
        print("tce_v4 inventaire_hors_tce=" + json.dumps([
            {"name": row["name"], "category": row.get("category")}
            for row in catalog.get("skills", []) if row["name"] not in set(names)
        ], ensure_ascii=False))
        missing = set(names) - discovered
        if missing:
            raise SystemExit("Skills non découverts : " + ", ".join(sorted(missing)))
        if args.cleanup_legacy and obsolete & discovered:
            raise SystemExit("Anciens skills encore actifs : " + ", ".join(sorted(obsolete & discovered)))
        relevant = sorted(name for name in discovered if any(
            word in name for word in ("devis", "travaux", "catalogue", "securite-donnees")))
        print("tce_v4 autres_skills_metier=" + json.dumps(relevant, ensure_ascii=False))
        viewed = skill_view("blueseatra-tce-core")
        if "Contrat" not in str(viewed):
            raise SystemExit("Noyau introuvable via skill_view")
        print("tce_v4 decouverte_hermes=25 noyau_charge=ok")
    if args.smoke:
        # Requête synthétique locale uniquement. La clé reste dans le processus
        # du conteneur ; aucune valeur sensible, aucun client ni prix n'est envoyé.
        schema = {"type": "object", "additionalProperties": False, "properties": {
            "quantite_ballon": {"type": "integer"},
            "capacite_l": {"type": "integer"},
            "fournir_evier": {"type": "boolean"},
            "quantite_prises": {"type": "null"},
        }, "required": ["quantite_ballon", "capacite_l", "fournir_evier", "quantite_prises"]}
        payload = {
            "model": "qwen2.5:7b", "provider": "custom:ollama", "stream": False,
            "messages": [
                {"role": "system", "content": (
                    "Extrais uniquement le JSON demandé. Quantité inconnue=null. "
                    "Une capacité n'est pas une quantité. Raccorder ne signifie pas fournir. "
                    "Aucun prix. Schéma : " + json.dumps(schema))},
                {"role": "user", "content": (
                    "Fourniture et pose d'un chauffe-eau 150 L. "
                    "Raccorder l'évier existant. Prévoir des prises, nombre à relever.")},
            ],
            "response_format": {"type": "json_schema", "json_schema": {
                "name": "tce_smoke", "schema": schema, "strict": True}},
        }
        request = urllib.request.Request(
            "http://hermes-passerelle:8642/v1/chat/completions",
            data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json",
                     "Authorization": "Bearer " + os.environ["API_SERVER_KEY"],
                     "X-Hermes-Session-Id": str(uuid.uuid4())},
        )
        with urllib.request.urlopen(request, timeout=240) as response:
            result = json.load(response)
        content = result["choices"][0]["message"]["content"]
        extracted = json.loads(content)
        expected = {"quantite_ballon": 1, "capacite_l": 150,
                    "fournir_evier": False, "quantite_prises": None}
        if extracted != expected:
            raise SystemExit("tce_v4 smoke_modele=ECHEC (réponse non conforme)")
        print("tce_v4 smoke_modele=qwen2.5:7b resultat=OK (4 assertions)")


if __name__ == "__main__":
    main()
