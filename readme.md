# last-feed

有些站点的rss输出只包含文章摘要 该程序可以自动获取获取原文 生成含有全文的rss输出


## 部署

该程序需要 `redis` 以及 `--harmony` 参数运行nodejs

```
node --harmony src/last-server
```

目前原文加载后 生成 `clean view` 需要自定义解析器

参考 `src/parser/` 中的具体实现
