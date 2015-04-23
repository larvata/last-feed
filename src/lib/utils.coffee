
module.exports.url2filename=(url)->
  url.replace(/^http:\/\//,'').replace(/[\/|\.]/g,'-')

