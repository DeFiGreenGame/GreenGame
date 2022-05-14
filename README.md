# RUN

```
docker run --rm ethereum/solc:0.8.13 --help
docker run --rm -v $(pwd):/sources ethereum/solc:0.8.13 -o /sources/output --abi --bin /sources/GreenGame.sol --optimize --optimize-runs 200 --gas --overwrite
```