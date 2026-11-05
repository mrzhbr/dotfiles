#!/usr/bin/env python3
"""Exercise the selected interpreter without personal HOME, kernels or user-site imports."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def notebook_check():
    import nbformat
    from nbclient import NotebookClient

    executable = str(Path(sys.executable).resolve())
    source = f"""import sys
from pathlib import Path
assert str(Path(sys.executable).resolve()) == {executable!r}
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
df = pd.DataFrame(np.arange(6).reshape(3, 2), columns=['x', 'y'])
assert int(df.x.sum()) == 6
plt.plot(df.x, df.y)
plt.savefig('health.png')
plt.close()
print('MISE_NOTEBOOK_OK')
"""
    notebook = nbformat.v4.new_notebook(cells=[nbformat.v4.new_code_cell(source)])
    client = NotebookClient(notebook, timeout=60, kernel_name="mise-health-check")
    manager = client.create_kernel_manager()
    manager.transport = "ipc"
    manager.ip = str(Path.cwd() / "kernel-ipc")
    client.execute()
    if not any(
        "MISE_NOTEBOOK_OK" in output.get("text", "")
        for output in notebook.cells[0].outputs
    ):
        raise RuntimeError("Notebook execution did not produce its success marker")
    if not Path("health.png").read_bytes().startswith(b"\x89PNG"):
        raise RuntimeError("Notebook did not produce a valid PNG")
    print(
        "Isolated Jupyter kernel, NumPy/Pandas computation and Matplotlib PNG passed."
    )


def main():
    # Keep IPC paths below macOS's AF_UNIX limit; this directory is test-owned.
    with tempfile.TemporaryDirectory(
        prefix="mise-jupyter-health-", dir="/tmp"
    ) as directory:
        home = Path(directory)
        kernel = home / "data/kernels/mise-health-check"
        kernel.mkdir(parents=True)
        (kernel / "kernel.json").write_text(
            json.dumps(
                {
                    "argv": [
                        sys.executable,
                        "-I",
                        "-m",
                        "ipykernel_launcher",
                        "-f",
                        "{connection_file}",
                    ],
                    "display_name": "Temporary mise health check",
                    "language": "python",
                }
            )
        )
        env = {
            "HOME": str(home),
            "PATH": os.pathsep.join(
                [str(Path(sys.executable).parent), "/usr/bin", "/bin"]
            ),
            "JUPYTER_DATA_DIR": str(home / "data"),
            "JUPYTER_CONFIG_DIR": str(home / "config"),
            "JUPYTER_RUNTIME_DIR": str(home / "runtime"),
            "IPYTHONDIR": str(home / "ipython"),
            "MPLCONFIGDIR": str(home / "matplotlib"),
            "OPENBLAS_NUM_THREADS": "1",
        }
        subprocess.run(
            [sys.executable, "-I", str(Path(__file__).resolve()), "--worker"],
            cwd=home,
            env=env,
            check=True,
            timeout=90,
        )


if __name__ == "__main__":
    if sys.argv[1:] == ["--worker"]:
        notebook_check()
    elif not sys.argv[1:]:
        main()
    else:
        raise SystemExit("usage: python -I scripts/check-jupyter.py")
