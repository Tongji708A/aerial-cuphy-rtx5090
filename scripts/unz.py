#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
"""Unzip that preserves symlinks (MATLAB Runtime zip). Usage: unz.py <zip> <dest>"""
import zipfile,os,stat,sys
z=zipfile.ZipFile(sys.argv[1]); d=sys.argv[2]; n=0
for i in z.infolist():
    p=os.path.join(d,i.filename); m=i.external_attr>>16
    if i.is_dir(): os.makedirs(p,exist_ok=True); continue
    os.makedirs(os.path.dirname(p),exist_ok=True)
    if os.path.lexists(p): os.remove(p)
    if stat.S_ISLNK(m):
        os.symlink(z.read(i).decode(),p); n+=1
    else:
        with z.open(i) as s, open(p,'wb') as f:
            while True:
                b=s.read(1<<20)
                if not b: break
                f.write(b)
        if m: os.chmod(p,stat.S_IMODE(m))
print("symlinks",n)
