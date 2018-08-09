## #dapp-wll
在SLU公链上设计了强大、安全的智能合约实现WLL，WLL总量100亿，根据算力由矿工自行挖出。智能合约启用了数学安全模型，并对owner、manager进行了约定，对于矿工来说涉及的功能有：
1. 确认矿工资格。用户购买矿机后，系统会调用智能合约approveMiner(address _miner)进行矿工资格确认。
2. 矿工挖矿。符合条件后开始挖矿，用户随时提币确认，确认后调用智能合约mint(address _receiver, uint256 _value)，矿工进帐【提币确认前，用户需要自己提供SILUBIUM地址，可以直接使用交易所的钱包地址】。
3. WLL价值传递。挖矿确认后的代币可以随时在交易所变现。
4. WLL地址上需要充值一定的SLU作为GAS费用，不论金额大小，每次操作需消耗手续费 0.005SLU左右，执行操作时预估费用，操作结束后会以GAS找零方式退回未用完的手续费。

### 接口调用说明

请根据以下步骤自行搭建内部服务器：

#### 一、安装SILUBIUM区块链节点
1. 根据服务器操作系统类型下载节点最新版本：http://update.silubium.org
2. 安装成功后，建议自行指定数据目录，如：/opt/sludata，并在该目录建立配置文件silubium.conf  
```
#启用节点rpc服务
server=1
#连接rpc服务的用户名和密码，与在接口配置文件保持一致
rpcuser=deaking20180807
rpcpassword=sfdlsddfs3454545821#$
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

#### 二、安装接口程序
1. 安装jdk8
