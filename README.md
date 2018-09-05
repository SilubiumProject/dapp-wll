## #dapp-wll
在SLU公链上设计了强大、安全的智能合约实现WLL，WLL总量100亿，根据算力由矿工自行挖出。智能合约启用了数学安全模型，并对owner、manager进行了约定，对于矿工来说涉及的功能有：
1. 确认矿工资格。用户购买矿机后，系统会调用智能合约approveMiner(address _miner)进行矿工资格确认。
2. 矿工挖矿。符合条件后开始挖矿，用户随时提币确认，确认后调用智能合约mint(address _receiver, uint256 _value)，矿工进帐【提币确认前，用户需要自己提供SILUBIUM地址，可以直接使用交易所的钱包地址】。
3. WLL价值传递。挖矿确认后的代币可以随时在交易所变现。
4. WLL地址上需要充值一定的SLU作为GAS费用，不论金额大小，每次操作需消耗手续费 0.005SLU左右，执行操作时会预扣费用，区块确认后会以GAS找零方式退回未用完的手续费。

### 接口调用说明

请根据以下步骤自行搭建内部服务器：

#### 一、安装SILUBIUM区块链节点
1. 根据服务器操作系统类型下载节点最新版本：http://update.silubium.org
2. 安装成功后，建议自行指定数据目录，如：/opt/sludata，并在该目录下建立配置文件silubium.conf  
```
#启用节点rpc服务
server=1
#连接rpc服务的用户名和密码，与在接口配置文件保持一致
rpcuser=deaking20180807
rpcpassword=sfdlsddfs345454582
#连接超时参数(秒)
rpcclienttimeout=600
#测试链监听端口
rpcport=16906
#主链监听端口
#rpcport=6906
```
在开发期间可以启动测试链进行调试  
主链： ./silubiumd --datadir=/opt/sludata  
测试链：./silubiumd --datadir=/opt/sludata --testnet  
3. 服务器正常启动节点程序后，需要开放外网端口5906（主链）或15906（测试链），节点通过该端口自动同步区块链数据。
4. 为了钱包节点安全，对钱包可以进行加密。执行：
./silubium-cli --datadir=/opt/sludata  encryptwallet "你的密码"

#### 二、安装接口程序
1. 安装jdk8
2. 将zhaishi.jar和application.properties下载到服务器同一目录中，可调整application.properties中的参数值，但不要对属性进行增减。
```
#节点类型，main表示主链，test表示测试链
#network.type=main
network.type=test
#接口监听端口，可通过 http://127.0.0.1:7010访问
server.port=7010
#通过调用api生成的私钥
dncrypt.password.privatekey=MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg6VikQb818txMAQzUkNcn+0tuM5sjOxGxAX9V9T1FzROgCgYIKoZIzj0DAQehRANCAAR9MtQeNhbnLRyzCq2IpZGN+x9OodHnL+DaB3s6+r6ZIxj6IlYGeIyDba/YoRQxvr0hRFcqV4u6QDje42n/TP32
#rpc调用参数，与silubium.conf保持一致
coin.rpc=http://deaking20180804:sfdlsddfs345454582@127.0.0.1:16906/
#无量链的核心参数
coin.name=Worldless Token - TEST7
coin.unit=WLL7
#钱包密码密文，明文密码长度不要超过40位
coin.password=BAGLFj40F6ktamlPkcl6ldfclWMjCsu7cyhNLHp4eBRL/aHLMyYN2g+tjsP80gCtl8rEHV2diMGvUhZgK/gXkbGtFp1xgkdvIuLVhaTOeVAQO9E4cE6mSEEoGxtSww93WrE=
#区块链最少确认次数
transaction.minconf=10
#合约地址
token.address=cb8d56b76f1ce543b3a974d2ead4a2a7edc80fb7
#币种精度
token.decimal=8
```
3. 启动接口程序：java -jar zhaishi.jar
4. 访问 http://127.0.0.1:7010/index.html 进行接口调试。

#### 三、测试过程
1. 若对钱包进行了加密，使用接口生成密钥对（公钥+私钥），用公钥对密码进行加密，将密文密码配置到coin.password，将私钥配置到dncrypt.password.privatekey，重启jar。
2. 从节点中获一个新slu地址作为合约的管理（manager）地址（如：SLSiqnZLyvKbyJ6F5U7SSFDkxTSkKfmuZ4M3），执行：  
./silubium-cli --datadir=/opt/sludata getnewaddress 
3. 与合约部署方(owner)联系，对manager授权并预挖20亿（200000000000000000，需要补充8个0作为精度），manager地址上需要充值slu作为GAS
4. 从节点中获一个新slu地址作为合约的矿工(miner)地址（如：SLSSpo2fcRTQDnZYe1MXjRBj9NSi1yGoVRsX）【实际运行时，由矿工自行提供地址】  
（1）授权矿工：  http://127.0.0.1:7010/rpc/option?optionType=6530fa45&fromAddress=manager地址&toAddress=minter地址&amount=0  
（2）矿工挖矿：  http://127.0.0.1:7010/rpc/option?optionType=40c10f19&fromAddress=manager地址&toAddress=minter地址&amount=1000  
5. 调用接口成功后，会返回message的值，该值为交易编号，执行以下命令可以查询交易是否确认  
./silubium-cli --datadir=/opt/sludata gettransaction 交易编号  
6. 主链区块浏览器可查看交易情况：https://silkchain2.silubium.org ，测试链只能通过命令./silubium-cli查看。

#### 四、合约部署【主链】
无量链部署合约地址为：[2e0000b2e2325f649dc43d960f03d7b6deda72dd](https://silkchain2.silubium.org/contract/2e0000b2e2325f649dc43d960f03d7b6deda72dd)
