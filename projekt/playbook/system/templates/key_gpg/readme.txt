---
# verzeichniss
templates
    key_gpg
        .gnupg
            openpgp-revocs.d
                E5096E87EA52B4163F318B247DE3CA01DC097508.rev
                EC9B532B19A854573421DD0AA5C8568E7D859EAF.rev
            private-keys-v1.d
                4D6D6974FCA38959F603CAE53AE0C1E1DBA9B79B.key
                040A06860A3BBDF60EC581A2D3D127789C89607E.key
                AA5ABF49E861089E0E8BA5C9D47B812D22568ACA.key
                E1B8C09D1C03CBF9E896A35F15D51AB4344E52C6.key
            pubrin.kbx
            pubrin.kbx
            trustdb.gpg

hier liegen die  mit den 2 Ordner 
# Eingaben:
# 1) RSA and RSA
# 2) 4096
# 3) 0 (kein Ablauf)
# Name: aptly_key
# Email: g<email> 
# comment: Apt Key self_repo
gpg: /home/max/.gnupg/trustdb.gpg: trustdb created
gpg: key 7DE3CA01DC097508 marked as ultimately trusted
gpg: directory '/home/max/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/home/max/.gnupg/openpgp-revocs.d/E5096E87EA52B4163F318B247DE3CA01DC097508.rev'
public and secret key created and signed.

pub   rsa4096 2026-01-03 [SC]
      E5096E87EA52B4163F318B247DE3CA01DC097508
uid                      aptly_key (Repo Key) <<email> >
sub   rsa4096 2026-01-03 [E]

======================================================================================
gpg --full-generate-key

# Eingaben:
# 1) RSA and RSA
# 2) 4096
# 3) 0 (kein Ablauf)
# Name: git_repo
# Email: <email> 
# Passphrase: fug75ger

gpg: key A5C8568E7D859EAF marked as ultimately trusted
gpg: revocation certificate stored as '/home/max/.gnupg/openpgp-revocs.d/EC9B532B19A854573421DD0AA5C8568E7D859EAF.rev'
public and secret key created and signed.

pub   rsa4096 2026-01-03 [SC]
      EC9B532B19A854573421DD0AA5C8568E7D859EAF
uid                      git_repo (Git Key) <<email> >
sub   rsa4096 2026-01-03 [E]


# Keys anzeigen
gpg --list-secret-keys --keyid-format=long