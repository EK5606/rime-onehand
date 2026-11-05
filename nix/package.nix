{
  lib,
  stdenvNoCC,
  version ? "3.1",
}:

stdenvNoCC.mkDerivation {
  pname = "rime-onehand";
  inherit version;

  src = ../.;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/rime-data
    install -m644 one_hand.schema.yaml one_hand.dict.yaml $out/share/rime-data/
    cp -r dicts $out/share/rime-data/dicts
    cp -r lua $out/share/rime-data/lua

    runHook postInstall
  '';

  meta = with lib; {
    description = "Rime 单手笔顺输入法（中英混输 fork）";
    homepage = "https://github.com/EK5606/rime-onehand";
    license = licenses.gpl3Plus;
    platforms = platforms.all;
  };
}
