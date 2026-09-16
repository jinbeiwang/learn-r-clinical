/* R 运行时高亮：先转义后单遍分词，禁止多遍 replace（历史事故：占位符二次污染） */
function hl(src){
  function esc(s){return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}
  try{
    var TOKEN=/(#[^\n]*)|("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(<-|->>|->|\|>|%[^%\n]*%)|(\b(?:function|if|else|for|while|repeat|return|next|break|library|require|requireNamespace|local|tryCatch|withCallingHandlers|in|NULL|NaN|Inf|TRUE|FALSE|NA|NA_integer_|NA_real_|NA_character_)\b)|(\b[A-Za-z][A-Za-z0-9._]*::)|(\b[A-Za-z._][A-Za-z0-9._]*(?=\s*\())|(\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b)/g;
    var out='',last=0,m;
    while((m=TOKEN.exec(src))!==null){
      if(m[0].length===0){TOKEN.lastIndex++;continue;}
      out+=esc(src.slice(last,m.index));
      var t=esc(m[0]);
      if(m[1])out+='<span class="tok-com">'+t+'</span>';
      else if(m[2])out+='<span class="tok-str">'+t+'</span>';
      else if(m[3])out+='<span class="tok-op">'+t+'</span>';
      else if(m[4])out+='<span class="tok-kw">'+t+'</span>';
      else if(m[5])out+='<span class="tok-ns">'+t+'</span>';
      else if(m[6])out+='<span class="tok-fn">'+t+'</span>';
      else if(m[7])out+='<span class="tok-num">'+t+'</span>';
      last=m.index+m[0].length;
    }
    out+=esc(src.slice(last));
    return out;
  }catch(e){return esc(src);}
}
if (typeof document!=='undefined') document.addEventListener('DOMContentLoaded',function(){
  document.querySelectorAll('code.lang-r').forEach(function(c){c.innerHTML=hl(c.textContent);});
  document.querySelectorAll('pre.code, pre.out').forEach(function(p){p.style.whiteSpace='pre';});
  /* 复制按钮 */
  document.querySelectorAll('pre.code').forEach(function(p){
    var b=document.createElement('button');b.className='copy';b.textContent='复制';
    b.onclick=function(){navigator.clipboard.writeText(p.textContent);b.textContent='已复制';setTimeout(function(){b.textContent='复制';},1500);};
    p.appendChild(b);
  });
  /* 测验：点击判定 + 展开解析 */
  document.querySelectorAll('.quiz').forEach(function(q){
    var ans=q.getAttribute('data-answer');
    q.querySelectorAll('.quiz-opt').forEach(function(btn){
      btn.onclick=function(){
        q.querySelectorAll('.quiz-opt').forEach(function(x){x.classList.remove('right','wrong');});
        btn.classList.add(btn.getAttribute('data-opt')===ans?'right':'wrong');
        q.classList.add('revealed');
      };
    });
  });
  /* TOC scrollspy */
  var links=[].slice.call(document.querySelectorAll('.toc a'));
  if(links.length&&'IntersectionObserver' in window){
    var io=new IntersectionObserver(function(es){es.forEach(function(e){
      if(e.isIntersecting){links.forEach(function(l){l.classList.toggle('on',l.getAttribute('href')==='#'+e.target.id);});}
    });},{rootMargin:'-10% 0px -80% 0px'});
    document.querySelectorAll('article h2[id]').forEach(function(h){io.observe(h);});
  }
  /* 暗色切换 */
  var tt=document.getElementById('theme-toggle');
  if(tt)tt.onclick=function(){document.body.classList.toggle('dark');};
  /* 顶部进度条 */
  var pb=document.querySelector('.progress');
  if(pb)addEventListener('scroll',function(){
    var h=document.documentElement;
    var den=h.scrollHeight-h.clientHeight;
    pb.style.width=(den>0?(h.scrollTop/den*100):0)+'%';
  });
});
if (typeof module!=='undefined') module.exports={hl};
