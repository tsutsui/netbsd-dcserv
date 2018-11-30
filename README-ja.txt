DCserv - NetBSD/dreamcast クライアント向け NFS サーバーキット


1. DCserv って何?

この "DCserv" イメージは、NetBSD/dreamcast をブートするために必要な
「NFS 上のルートファイルシステム」を簡単に用意できるようにしたものです。


2. DCserv イメージの内容

このイメージには、ブート可能な NetBSD/i386 ファイルシステムイメージが含まれており、
dhcpd(8), mountd(8), nfsd(8) などのデーモンが自動的に起動するようになっています。
また、NetBSD/dreamcast ファイルシステムを NFS でエクスポートするようになっており、
これには X のサーバーとクライアントを含む、すべてのリリースバイナリーが含まれています。


3. 必要なもの

- x86 ベースの PC で、NIC を持ち、USB デバイスからのブートが可能なもの
- 10BASE-T クロスケーブル (または HUB)
- MIL-CD に対応した Dreamcast
- ブロードバンドアダプタまたは LAN アダプタ
- Dreamcast キーボード
- Dreamcast マウス (必須ではありませんが、X サーバーを使う場合は必要です)


4. DCserv の使い方

1) 2GB (以上) の USB フラッシュメモリーに、
    このイメージを、gunzip(1) と dd(1) を使って書き込みます
   (Windows 用の Rawrite32.exe ツールも使えます)。
    Rawrite32.exe ツールは以下のサイトにあります:
    http://www.NetBSD.org/~martin/rawrite32/
2) USB メモリーを x86 PC に挿し、そこから起動します (起動方法はマシン毎に異なります)
3) Dreamcast と x86 DCserv PC を 10BASE-T クロスケーブルなどで接続します。
   註: DCserv は独自のアドレス (10.0.0.xxx) で dhcpd(8) を動かしますので、
   他のネットワークには接続しないでください。
4) ブート可能な NetBSD/dreamcast CD-R を準備します
   (詳細は別の文書で調べてください。または、"DCburn" ツールのイメージを使えば一発です)
5) NetBSD/dreamcast をブートして、"root device:" プロンプトで "rtk0" 
   (ブロードバンドアダプタを使っている場合) または "mbe0" (LAN アダプタを使っている場合) と入力します
6) その後のプロンプト (dump device, file system, init path) では、enter を押します
7) ゆっくりしていってね!

注： NetBSD 8.0版では dhcpd(8) が起動時にデーモンとして起動しないという問題があります。
その場合は root でログインして手動で /usr/sbin/dhcpd を起動してください。

5. その他

20130522 版では、NetBSD 6.1 のリリースバイナリーを使っています。
20151122 版では、NetBSD 7.0 のリリースバイナリーを使っています。
20151122 版では、NetBSD 8.0 のリリースバイナリーを使っています。


6. 変更履歴

20101113a:
 - 最初の公開版

20130522:
 - NetBSD 6.1 用に更新

20151122:
 - NetBSD 7.0 用に更新

20181130:
 - NetBSD 8.0 用に更新

---
Izumi Tsutsui
tsutsui@NetBSD.org
