// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract MultiSig {
    address[] public signers; //bu cuzdanı  kımler yonetıyor imzacılar
    uint256 public requiredConfirmations; // 1 ıslem ıcın kac ımza gerekli

    uint256 public nonce; //Her bır transectıonun nonce degerı olmalıdır 1->2->3 gıbı gıdıcek
    mapping(uint256 => Tx) public nonceToTx; //her bır nonce degerıne karsılık Tx tutucaz
    //kimlerin onayladıgını tutmamız gerek
    mapping(uint256 => mapping(address => bool)) public txConfirmers; //her ır nonce ıcın ılgılı adresler onayladımı onaylamadımı verıelrın tutuldugu yerdır

    event NewProposal(address proposer, uint256 id); //kim onerdi ve noncesi
    event Executed(address executor, uint256 id, bool success);

    struct Tx {
        //transection bilgileri
        address proposer; //kımının onerdiği kım yapalım dedı
        uint256 confirmations; //kac kısı ımzaladı
        bool executed; //gerceklestımı
        uint256 deadline; // son teslim tarihi seneye 1 eth degılde 0.5 eth lazım gıbı bıtıs tarıhı olsun
        //bir transectionda olması gerekenler
        address txAddress; //to gibi nereye gonderılcek
        uint256 value; //kac eth tasıycak
        bytes txData; //ıslemı acıklıyan veri
    }

    constructor(address[] memory _signers, uint256 _requiredConfirmations) {
        require(_signers.length > 0, "Any signer."); //array dolu olsun
        require(isUnique(_signers), "Duplicate addresses."); //aynı adresı 1 den fazla gondereme
        require(
            _requiredConfirmations <= _signers.length, //yonetıcılerden fazla onay istenemez dedik mantıken 9 kullanıcıya 10 onay ıstenırse calısmaz bu contract
            "Not enough signer."
        );

        signers = _signers;
        requiredConfirmations = _requiredConfirmations;
    }

    receive() external payable {}

    fallback() external payable {}

    //Altakı fonksıyonları sadece yonetıcıler ımzalayıcılar yonetebılsınler
    function proposeTx(
        //transectıon onerme işlemi
        uint256 _deadline,
        address _txAddress,
        uint256 _value,
        bytes memory _txData
    ) external onlySigners {
        require(_deadline > block.timestamp, "Time out"); //deadline gecmıs bır zaman olmasın dedik

        Tx memory _tx = Tx({
            proposer: msg.sender, //cagıran kullanıcı onerdi
            confirmations: 0, //onerı yenı onay yok
            executed: false, //yenı oldugu ıcın gerceklesmedi
            deadline: _deadline, //parametreden aldık
            txAddress: _txAddress,
            value: _value,
            txData: _txData
        });

        nonceToTx[nonce] = _tx; //onerıyı tuttuk

        emit NewProposal(msg.sender, nonce);
        nonce++; //bir artır
    }

    //kullanici hangı tx yı onaylıyor
    function confirmTx(uint256 _nonce) external onlySigners {
        //onaylama
        require(_nonce < nonce, "Not exists."); //boyle bır tx varmı
        require(txConfirmers[_nonce][msg.sender] == false, "Already approved."); //kullanıcı bu tx yı daha once onayladımı onaylamadımı onaylamadı ıse devam etsın
        require(nonceToTx[_nonce].deadline > block.timestamp, "Time out"); //bu işlemin dead linesi gectimi gecmedimi
        require(nonceToTx[_nonce].executed == false, "Already executed"); //bu işlem çoktan onaylandımı bu kısının onayına gerek kalamdan onay sayısına ulasıldımı ulasıldı ıse gerek yoktur bu kullanıcıya

        nonceToTx[_nonce].confirmations++; //onaylayan sayısını artır
        txConfirmers[_nonce][msg.sender] = true; //bu kullanıcı bunu onayladıgını yazdık
    }

    //hangi tx yı onaylıyoz
    function rejectTx(uint256 _nonce) external onlySigners {
        //ret etme
        require(_nonce < nonce, "Not exists."); //tx varmı
        require(
            txConfirmers[_nonce][msg.sender] == true,
            "Already non approved."
        ); //ret edılmıs bır ıslemı tekrar ret edemesin
        require(nonceToTx[_nonce].deadline > block.timestamp, "Time out"); //zaman gectımı
        require(nonceToTx[_nonce].executed == false, "Already executed"); //ret edılmıs bır ıselmı ret etmesıne gerek yok

        nonceToTx[_nonce].confirmations--; //onceden onayladıgı ıcın onu zalttık
        txConfirmers[_nonce][msg.sender] = false; //oyu fasle yapmak lazım
    }

    //
    function executeTx(uint256 _nonce) external onlySigners returns (bool) {
        require(_nonce < nonce, "Not exists."); //boyle bır tx varmı
        require(nonceToTx[_nonce].deadline > block.timestamp, "Time out"); //Zaman doldumu
        require(
            nonceToTx[_nonce].confirmations >= requiredConfirmations,
            "Already confirmed."
        ); //bu işlem onaylandımı onaylanmadımı
        require(nonceToTx[_nonce].executed == false, "Already executed"); //zaten excute edılen ıslemı bırdaha exequet yapmıyalım

        require(nonceToTx[_nonce].value <= address(this).balance); //bu işlemde bir value gonderılıyorsa bu degerın contratta bulunup bulunmadıgını kontrol edelım yani contrat bu etheri karsılıyormu

        nonceToTx[_nonce].executed = true; //bu ıslemı tamamlıyalım

        (bool txSuccess, ) = (nonceToTx[_nonce].txAddress).call{
            value: nonceToTx[_nonce].value
        }(nonceToTx[_nonce].txData); //txAddress e value ile birlikte txData yı gonderelim

        if (!txSuccess) nonceToTx[_nonce].executed = false; //basarılı degıl tx ın ıslemını acıcaz ustunde ıslem yapıla bılır bır hala getırcez

        emit Executed(msg.sender, _nonce, txSuccess); //basarılı ıse event dın
        return txSuccess; //basarı durumu donsun
    }

    function deleteTx(uint256 _nonce) external onlySigners {
        //onerıyı geri çek
        require(_nonce < nonce, "Not exists."); //boyle bır tx varmı
        require(nonceToTx[_nonce].executed == false, "Already executed"); //işlem onaylanmadı ıse daha bu işlem siline bilsin
        require(nonceToTx[_nonce].proposer == msg.sender, "Not tx owner."); //bu ıslemı sadece olustran ksııs sıle bılsın
        require(
            nonceToTx[_nonce].confirmations < requiredConfirmations,
            "Already confirmed."
        ); //coktan onaylandı ıse bu tx bu ıslem sılınemesin

        nonceToTx[_nonce].executed = true; //true olunca bunun ustunde kımse ıslem yapamıycak
    }

    //gonderılen dızı ıcerısınde tekrar eden degerler var ıse hata fıraltıcaktır
    function isUnique(address[] memory arr) private pure returns (bool) {
        for (uint256 i = 0; i < arr.length - 1; i++) {
            for (uint256 j = i + 1; j < arr.length; j++) {
                require(arr[i] != arr[j], "Duplicate address.");
            }
        }

        return true;
    }

    modifier onlySigners() {
        //yonetıcıler calıstıra bılsın sadece
        bool signer = false;

        for (uint256 i = 0; i < signers.length; i++) {
            //dizide gez
            if (signers[i] == msg.sender) signer = true; //calsıtran adres var ise true yap
        }

        require(signer, "Not signer."); //true ıse gec false ıse hata ver
        _;
    }
}

contract A {
    uint256 public x;

    function increment() external {
        x++;
    }

    function getFnData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("increment()"); //yukarıdakı sozlesmedekı data yerıne buradan donen verıyı verırsek ve sozlesme basarılı olur use 162. satırdakı increment() fonksıyonu calsııcaktır
    }
}
