"""Vérification non destructive du pack, puis découverte réelle dans Hermes."""
import argparse
import hashlib
import json
import os
import shutil
import urllib.request
import uuid
from pathlib import Path
import yaml


def obsolete_leaf_name(path: Path, local_root: Path, obsolete: set[str]):
    """Identifier un ancien skill, jamais un dossier collectif ni une citation."""
    root = local_root.resolve()
    folder = path.parent
    if path.is_symlink() or folder.is_symlink() or not path.resolve().is_relative_to(root):
        return None
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        return None
    end = next((i for i, line in enumerate(lines[1:], 1) if line == "---"), None)
    if end is None:
        return None
    front = yaml.safe_load("\n".join(lines[1:end])) or {}
    name = front.get("name") if isinstance(front, dict) else None
    if name not in obsolete:
        return None
    if folder.resolve() == root or folder.name != name:
        raise SystemExit("Ancien skill dans un dossier ambigu : archivage refusé")
    if any(child != path for child in folder.rglob("SKILL.md")):
        raise SystemExit("Ancien skill dans un dossier collectif : archivage refusé")
    return name


def smoke_schema_valid(value):
    keys = {"quantite_ballon", "capacite_l", "fournir_evier", "quantite_prises"}
    if not isinstance(value, dict) or set(value) != keys:
        return False
    if type(value["fournir_evier"]) is not bool:
        return False
    return all(v is None or (type(v) is int and v >= 0)
               for v in (value[k] for k in keys - {"fournir_evier"}))


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
    config_path = Path("hermes/config.yaml") if args.files else Path("/opt/data/config.yaml")
    config = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    disabled = set((config.get("skills") or {}).get("disabled") or [])
    if set(names) & disabled:
        raise SystemExit("Un skill TCE requis a été désactivé")
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
                if not path.exists():
                    continue
                name = obsolete_leaf_name(path, local_root, obsolete)
                if name is None:
                    continue
                folder = path.parent
                target = backup / folder.relative_to(local_root)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(folder), str(target))
                print("tce_v4 ancien_skill_archive=" + name)
        # API de découverte Hermes, aucun appel IA et aucun secret affiché.
        from tools.skills_tool import skills_list, skill_view
        catalog = skills_list()
        catalog = json.loads(catalog) if isinstance(catalog, str) else catalog
        discovered = {row["name"] for row in catalog.get("skills", [])}
        if disabled & discovered:
            raise SystemExit("La désactivation de skills n'est pas appliquée")
        print(f"tce_v4 skills_generaux_desactives={len(disabled)} skills_actifs={len(discovered)}")
        print("tce_v4 inventaire_hors_tce=" + json.dumps([
            {"name": row["name"], "category": row.get("category")}
            for row in catalog.get("skills", []) if row["name"] not in set(names)
        ], ensure_ascii=False))
        missing = set(names) - discovered
        if missing:
            raise SystemExit("Skills non découverts : " + ", ".join(sorted(missing)))
        if args.cleanup_legacy and obsolete & discovered:
            raise SystemExit("Anciens skills encore actifs : " + ", ".join(sorted(obsolete & discovered)))
        if args.cleanup_legacy:
            print("tce_v4 anciens_skills_actifs=0")
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
            "quantite_ballon": {"type": ["integer", "null"], "minimum": 0,
                                "description": "Nombre de chauffe-eau demandés, distinct de leur capacité."},
            "capacite_l": {"type": ["integer", "null"], "minimum": 0,
                          "description": "Capacité unitaire du chauffe-eau en litres, si donnée."},
            "fournir_evier": {"type": "boolean", "description": (
                "Vrai seulement si l'achat ou la fourniture d'un évier est explicitement demandé. "
                "La fourniture d'un autre appareil ne s'étend pas à l'évier. "
                "Poser, réparer ou raccorder un évier existant n'est pas fournir un évier neuf.")},
            "quantite_prises": {"type": ["integer", "null"], "minimum": 0,
                                "description": "Nombre de prises explicitement donné ; null si à relever."},
        }, "required": ["quantite_ballon", "capacite_l", "fournir_evier", "quantite_prises"]}
        contract = (root / "blueseatra-tce-core/references/contrat-systeme.md").read_text(encoding="utf-8")
        payload = {
            "model": "qwen2.5:7b", "provider": "custom:ollama", "stream": False,
            "messages": [
                {"role": "system", "content": contract + (
                    "\nÉtape de lecture ciblée : traite séparément chaque objet et son action. "
                    "Retourne uniquement les quatre champs de ce schéma, sans explication : "
                    + json.dumps(schema, ensure_ascii=False))},
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
        if not smoke_schema_valid(extracted):
            raise SystemExit("tce_v4 transport_schema=ECHEC (sortie non exploitable)")
        expected = {"quantite_ballon": 1, "capacite_l": 150,
                    "fournir_evier": False, "quantite_prises": None}
        score = sum(extracted[key] == expected[key] for key in expected)
        print(f"tce_v4 transport_schema=OK modele_brut={score}/4", flush=True)
        if extracted != expected:
            # Diagnostic limité aux quatre champs du test SYNTHÉTIQUE. Aucun
            # texte libre, document client, clé ou prompt n'est journalisé.
            observed = {}
            for key in expected:
                value = extracted.get(key) if isinstance(extracted, dict) else None
                observed[key] = {
                    "present": isinstance(extracted, dict) and key in extracted,
                    "type": type(value).__name__,
                    "value": value if type(value) in (int, float, bool, type(None)) else "[non-primitif]",
                }
            print("tce_v4 smoke_observe=" + json.dumps(observed), flush=True)
            print("tce_v4 smoke_champs_supplementaires=" + str(
                len(set(extracted) - set(expected)) if isinstance(extracted, dict) else -1), flush=True)
            print("tce_v4 smoke_modele_retour=" + str(result.get("model") or "non-indique")[:80], flush=True)
            # Une proposition IA incorrecte ne vaut jamais approbation. Ne pas
            # confondre cette mesure de qualité avec une panne d'infrastructure :
            # le SaaS doit être présent avec ses garde-fous et la revue humaine.
            print("tce_v4 qualite_modele=AVERTISSEMENT revue_metier_obligatoire", flush=True)
        else:
            print("tce_v4 qualite_modele=OK (4 assertions)", flush=True)
        with urllib.request.urlopen(
            "https://blueseatra-api.onrender.com/api/health", timeout=30
        ) as response:
            health = json.load(response)
        saas = health.get("tce") or {}
        if (health.get("status") != "healthy" or saas.get("version") != "4.0.0"
                or saas.get("skills") != 25 or saas.get("sha256") != h.hexdigest()):
            raise SystemExit("tce_v4 integration_saas=ECHEC (version protégée non identifiée)")
        print("tce_v4 integration_saas=OK commit=" + str(health.get("commit")), flush=True)


if __name__ == "__main__":
    main()
