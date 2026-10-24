'use strict';
// Locally authored reference-matched scenes; only project resources are reused.
window.motionDemoSessions = new Map();
window.mountMotionDemo = (host, id) => {
  const kind = id.replace('tool-', '');
  const info = {
    wheel:['转盘','今天怎么选，让转盘帮你决定','转动','再转一次'],
    groups:['随机分组','打散一点，遇见新伙伴','开始分组','重新分组'],
    lottery:['抽签','把一点小期待，交给随机','抽一签','再抽一签'],
    die:['掷骰子','一颗骰子，也有一点小惊喜','掷一下','再掷一次'],
    coin:['抛硬币','正面还是反面，交给这一抛','抛一下','再抛一次'],
    draw:['随机点名','','开始点名','再抽一位']
  }[kind];
  const esc = value => String(value).replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const icon = name => `<img src="resources/icons/${name}.svg" alt="">`;
  const art = (name,cls='')=>`<img class="${cls}" src="resources/illustrations/${name}" alt="">`;
  const initial = {
    wheel:['食堂一楼','食堂二楼','面馆','盖饭','轻食','饺子'],
    groups:['林晓','李禾','唐棠','顾言','沈念','许诺','周屿','陈安','陆晨','苏禾'],
    lottery:['今天也顺利','好事将近','去看晚霞','休息一下','勇敢出发','和友散步'],
    draw:['林晓','顾言','沈念','许诺','李禾','唐棠','周屿','陈安','陆晨','苏禾']
  };
  let state = {items:[...(initial[kind]||[])],used:[],repeat:false,groupMode:'limit',amount:4,last:null,scene:null,favorite:false};
  const saved = window.motionDemoSessions.get(id);
  if(saved) state = {...saved,items:[...saved.items],used:[...saved.used]};
  let busy=false, disposed=false;
  const animations = new Set();
  const $ = s=>host.querySelector(s);
  const choose = n=>{const v=new Uint32Array(1),limit=4294967296-4294967296%n;do{crypto.getRandomValues(v);}while(v[0]>=limit);return v[0]%n;};
  const persist = ()=>window.motionDemoSessions.set(id,{...state,items:[...state.items],used:[...state.used]});
  const hasList=['wheel','draw','groups','lottery'].includes(kind);
  const round=['draw','lottery'].includes(kind);
  const listTitle={wheel:'午餐怎么选',draw:'高数学小组',groups:'学习伙伴',lottery:'今日签池'}[kind];
  host.innerHTML=`<div class="motion-demo"><div class="demo-controls"><span>交互动效</span><label>速度 <select data-speed><option value="1">正常</option><option value="0.35">0.35× 慢速</option></select></label><label><input type="checkbox" data-reduce>减少动效</label></div><section class="demo-phone" aria-label="${info[0]}交互样板"><header class="demo-toolbar"><button data-back aria-label="返回">${icon('back')}</button><h3>${info[0]}</h3><button data-favorite aria-label="收藏" aria-pressed="${state.favorite}">${icon('star')}</button></header>${info[1]?`<p class="demo-subtitle">${info[1]}</p>`:''}<div class="demo-body">${hasList?`<div class="demo-list-row"><div class="demo-list-title">${icon(kind==='wheel'?'wheel':kind==='lottery'?'ticket':'users')}<strong>${listTitle} · <span data-count>${state.items.length}</span>${kind==='draw'||kind==='groups'?'人':'项'}</strong>${icon('down')}</div><button data-edit>${kind==='draw'?'管理名单':kind==='groups'?'编辑名单':kind==='wheel'?'编辑选项':'编辑签池'}</button></div>`:''}${round?'<div class="demo-segments"><button data-repeat="true">可重复</button><button data-repeat="false">不重复</button></div>':''}${kind==='groups'?'<div class="demo-segments"><button data-mode="count">按组数</button><button data-mode="limit">按人数上限</button></div><div class="demo-quantity"><span data-quantity-label>每组最多</span><button data-minus aria-label="减少">−</button><b data-quantity>4</b><button data-plus aria-label="增加">+</button><span data-quantity-unit>人</span></div>':''}<div class="demo-stage demo-${kind}"></div>${['wheel','die','coin'].includes(kind)?`<div class="demo-result-paper paper-surface paper-torn" style="--paper-color:${kind==='coin'?'#fff4d2':'#eee8fc'}"><small>${kind==='die'?'本次点数':kind==='coin'?'本次结果':'本次选中'}</small><p class="demo-result" role="status" aria-live="polite"></p><small>${kind==='die'?'1–6 等概率':kind==='coin'?'两面机会相同':'每个选项机会相同'}</small></div>`:''}${round?'<div class="demo-round"><div class="demo-progress"></div><div class="demo-progress-track"><i></i></div><small>切换页面保留本轮进度</small></div>':''}<button class="demo-play">${icon('shuffle')}<span>${info[2]}</span></button>${round?'<button class="demo-reset" data-reset>开始新一轮</button>':''}<p class="demo-hint" role="status"></p>${kind==='wheel'?'<div class="demo-legend"></div>':kind==='coin'?`<div class="demo-coin-legend">${art('coin-head.svg')}<span>星星正面</span>${art('coin-tail.svg')}<span>月牙反面</span></div>`:''}${kind==='draw'?'<div class="demo-history"><strong>本轮已抽</strong><div></div></div>':''}${['die','coin'].includes(kind)?'<p class="demo-footnote">结果仅本次展示，不保存历史</p>':''}</div><form class="demo-editor" hidden><h4>编辑${kind==='wheel'?'选项':kind==='lottery'?'签池':'名单'}</h4><label>每行一项，同名项分别保留<textarea rows="8" required></textarea></label><p>保存后重置本轮进度与本次结果。</p><div><button type="button" data-edit-cancel>取消</button><button type="submit">保存</button></div></form></section></div>`;
  $('[data-reduce]').checked=matchMedia('(prefers-reduced-motion: reduce)').matches;
  const stage=$('.demo-stage');
  const diePose = n=>'rotateX(-16deg) rotateY(-24deg) '+['rotateX(0deg)','rotateY(-90deg)','rotateX(-90deg)','rotateX(90deg)','rotateY(90deg)','rotateY(180deg)'][n];
  function buildStage() {
    stage.classList.remove('is-dealing');
    if(kind==='wheel') {
      const n=state.items.length,step=360/n;
      const sectors=state.items.map((text,i)=>{
        const a=(i*step-step/2-90)*Math.PI/180,b=a+step*Math.PI/180;
        const path=n===1?'<circle cx="180" cy="180" r="163" fill="#e4f2ff"/>':`<path d="M180 180 L${180+163*Math.cos(a)} ${180+163*Math.sin(a)} A163 163 0 ${step>180?1:0} 1 ${180+163*Math.cos(b)} ${180+163*Math.sin(b)} Z" fill="${['#e4f2ff','#eee4ff','#fff1bf','#e1f2e8','#ffe5ec','#ffe7d7'][i%6]}" stroke="#fff" stroke-width="3"/>`;
        const label=text.length>6?text.slice(0,5)+'…':text;
        return path+`<text transform="translate(180 180) rotate(${i*step})" x="0" y="${-100-label.length*8}" style="writing-mode:vertical-rl;text-orientation:upright" font-size="${n>10?12:16}" fill="#28364c">${esc(label)}</text>`;
      }).join('');
      stage.innerHTML=`<div class="demo-wheel-shell"><svg class="demo-wheel" viewBox="0 0 360 360" aria-label="选项转盘"><circle cx="180" cy="180" r="173" fill="#769dff" stroke="#fff" stroke-width="5"/>${sectors}<circle cx="180" cy="180" r="35" fill="#e7dcff" stroke="#fff" stroke-width="7"/></svg><svg class="demo-pointer" viewBox="0 0 44 54" aria-label="固定指针"><path d="M5 4H39L22 48Z" fill="#3867e8" stroke="white" stroke-width="4"/></svg></div>`;
      $('.demo-legend').innerHTML=state.items.map((text,i)=>`<span><i style="background:${['#e4f2ff','#eee4ff','#fff1bf','#e1f2e8','#ffe5ec','#ffe7d7'][i%6]}"></i>${esc(text)}</span>`).join('');
    } else if(kind==='draw') {
      stage.innerHTML=`${art('badge.svg','demo-badge sticker')}<small>准备好，抽一位同学吧</small><div class="demo-name-window"><div class="demo-reel"><div>等待点名</div></div></div><p class="demo-student-number">名单中的每位同学，机会相同</p>`;
    } else if(kind==='groups') {
      stage.innerHTML=`<p class="demo-group-caption">让每一位伙伴，都找到自己的小组</p><div class="demo-deck-stack"><span></span><span></span><div class="demo-deck">${art('groups.svg')}<strong>${state.items.length} 张姓名牌</strong></div></div><div class="demo-group-grid"></div>`;
    } else if(kind==='lottery') {
      stage.innerHTML=`<p class="demo-scene-caption">摇一摇，抽一份小期待</p><div class="demo-bag-scene"><div class="demo-bag-tickets"><i></i><i></i><i></i></div><div class="demo-slip-window"><div class="demo-slip paper-surface"><span></span></div></div>${art('lottery-bag.png','demo-bag')}${art('spark-yellow.svg','demo-spark demo-spark-one')}${art('spark-lavender.svg','demo-spark demo-spark-two')}</div>`;
    } else {
      const dots={1:[5],2:[1,9],3:[1,5,9],4:[1,3,7,9],5:[1,3,5,7,9],6:[1,3,4,6,7,9]};
      const body=kind==='die'?`<div class="demo-cube" style="transform:${diePose(3)}">${[1,2,3,4,5,6].map(n=>`<div class="demo-die-face face-${n}">${Array.from({length:9},(_,i)=>`<i class="${dots[n].includes(i+1)?'pip':''}"></i>`).join('')}</div>`).join('')}</div>`:`<div class="demo-coin"><div class="demo-coin-edge"></div>${art('coin-head.svg','demo-coin-front')}${art('coin-tail.svg','demo-coin-back')}</div>`;
      stage.innerHTML=`<p class="demo-scene-caption">${kind==='die'?'单个六面骰':'一枚硬币 · 两种可能'}</p><div class="demo-orbit"></div><div class="demo-shadow"></div><div class="demo-toss">${body}</div><p class="demo-scene-status">${kind==='die'?'向上抛起，轻轻落定':'星星和月牙，等一枚答案'}</p>`;
    }
  }
  function updateRound() {
    if(!round)return;
    $('.demo-progress').innerHTML=`<span>本轮已抽 <b>${state.used.length}</b> ${kind==='draw'?'人':'签'}</span><span>剩余 ${state.repeat?state.items.length:state.items.length-new Set(state.used).size} ${kind==='draw'?'人':'签'}</span>`;
    $('.demo-progress-track').hidden=state.repeat;
    if(state.repeat)$('.demo-progress').innerHTML=`<span>本轮已抽 <b>${state.used.length}</b> 次</span><span>完整签池／名单 · ${state.items.length} 项</span>`;
    $('.demo-progress-track i').style.width=`${Math.min(100,state.used.length/state.items.length*100)}%`;
    if(kind==='draw') $('.demo-history div').innerHTML=state.used.map(i=>`<span>${esc(state.items[i])} · ${String(i+1).padStart(4,'0')}</span>`).join('')||'<small>还没有抽取记录</small>';
  }
  function settings() {
    host.querySelectorAll('[data-repeat]').forEach(el=>el.setAttribute('aria-pressed',String(el.dataset.repeat===String(state.repeat))));
    host.querySelectorAll('[data-mode]').forEach(el=>el.setAttribute('aria-pressed',String(el.dataset.mode===state.groupMode)));
    if(kind==='groups'){
      $('[data-quantity]').textContent=state.amount;
      $('[data-quantity-label]').textContent=state.groupMode==='limit'?'每组最多':'分为';
      $('[data-quantity-unit]').textContent=state.groupMode==='limit'?'人':'组';
    }
    $('[data-favorite]').setAttribute('aria-pressed',String(state.favorite));
    updateRound();
  }
  function renderIdle() {
    buildStage();
    if(state.scene)stage.innerHTML=state.scene;
    const result=$('.demo-result');if(result)result.textContent=state.last?.text||'—';
    $('.demo-play span').textContent=state.last?info[3]:info[2];
    $('.demo-hint').textContent=state.last?.hint||({wheel:'指针停稳，再揭晓这次选择',groups:'人数均衡，每人只出现一次',lottery:'每支签，都是一份小期待',draw:'不重复模式，照顾到每一位同学',die:'点击投掷，等待骰子停稳',coin:'跳起，翻转，等它轻轻落下'}[kind]);
    settings();
  }
  async function move(node,frames,duration,easing='cubic-bezier(.18,.72,.2,1)') {
    if(disposed)throw new Error('disposed');
    const reduced=$('[data-reduce]').checked;
    const animation=node.animate(frames,{duration:reduced?1:duration/Number($('[data-speed]').value),easing,fill:'forwards'});
    animations.add(animation);await animation.finished;
    const end=frames[frames.length-1];for(const [key,value]of Object.entries(end))if(!['offset','easing','composite'].includes(key))node.style[key]=value;
    animation.cancel();animations.delete(animation);
  }
  function lock(value) {
    busy=value;host.querySelectorAll('button,select,input,textarea').forEach(el=>el.disabled=value);
    $('[data-back]').disabled=false;
    $('.demo-phone').setAttribute('aria-busy',String(value));
  }
  async function play() {
    if(busy||disposed)return;
    if(round&&!state.repeat&&new Set(state.used).size>=state.items.length){$('.demo-hint').textContent='本轮已抽完，点击“开始新一轮”继续';return;}
    lock(true);buildStage();$('.demo-hint').textContent='正在进行，稍等一下…';
    const result=$('.demo-result');if(result)result.textContent='…';
    let text,hint,chosen;
    try {
      if(kind==='wheel') {
        chosen=choose(state.items.length);text=state.items[chosen];
        const rotation=2160+(360-chosen*360/state.items.length)%360;
        await Promise.all([move($('.demo-wheel-shell>.demo-wheel'),[{transform:'rotate(0deg)'},{transform:`rotate(${rotation}deg)`}],3100),move($('.demo-pointer'),[{transform:'rotate(0deg)'},{transform:'rotate(-11deg)',offset:.14},{transform:'rotate(9deg)',offset:.3},{transform:'rotate(-7deg)',offset:.5},{transform:'rotate(4deg)',offset:.7},{transform:'rotate(0deg)'}],3100)]);
        hint=`指针已停稳，本次选中：${text}`;
      } else if(kind==='draw') {
        const pool=state.items.map((_,i)=>i).filter(i=>state.repeat||!state.used.includes(i));chosen=pool[choose(pool.length)];text=state.items[chosen];
        const rows=Array.from({length:20},()=>state.items[choose(state.items.length)]).concat(text);
        $('.demo-reel').innerHTML=rows.map(name=>`<div>${esc(name)}</div>`).join('');
        $('.demo-stage>small').textContent='名字滚动中…';$('.demo-student-number').textContent='正在揭晓这位同学';
        await move($('.demo-reel'),[{transform:'translateY(0)'},{transform:'translateY(-1200px)'}],1400);
        $('.demo-reel').innerHTML=`<div>${esc(text)}</div>`;$('.demo-reel').style.transform='';
        $('.demo-stage>small').textContent='本次抽中';$('.demo-student-number').textContent=`学号 2026${String(chosen+1).padStart(4,'0')}`;
        hint='切换页面保留本轮进度';
      } else if(kind==='lottery') {
        const pool=state.items.map((_,i)=>i).filter(i=>state.repeat||!state.used.includes(i));chosen=pool[choose(pool.length)];text=state.items[chosen];
        await move($('.demo-bag-scene'),[{transform:'rotate(0deg)'},{transform:'translateX(-6px) rotate(-9deg)',offset:.18},{transform:'translateX(5px) rotate(8deg)',offset:.38},{transform:'rotate(-5deg)',offset:.6},{transform:'rotate(3deg)',offset:.8},{transform:'rotate(0deg)'}],850);
        $('.demo-bag-tickets').style.visibility='hidden';$('.demo-slip span').textContent=text;
        if(text.length>5)$('.demo-slip span').style.cssText='writing-mode:horizontal-tb;font-size:13px;line-height:1.6;height:92px;overflow:auto';
        $('.demo-bag-scene').classList.add('is-revealed');
        await move($('.demo-slip'),[{transform:'translateY(154px)'},{transform:'translateY(-7px)',offset:.82},{transform:'translateY(0px)'}],750);
        $('.demo-scene-caption').textContent=text.length>16?'本次抽中 · 完整签文见下方':`本次抽中 · ${text}`;hint=text.length>5?`本次签文：${text}`:'切换页面保留本轮进度';
      } else if(kind==='groups') {
        const shuffled=state.items.map((name,i)=>({name,i}));for(let i=shuffled.length-1;i>0;i--){const j=choose(i+1);[shuffled[i],shuffled[j]]=[shuffled[j],shuffled[i]];}
        const count=state.groupMode==='limit'?Math.ceil(shuffled.length/state.amount):Math.min(state.amount,shuffled.length);
        const groups=Array.from({length:count},()=>[]);shuffled.forEach((person,i)=>groups[i%count].push(person));
        $('.demo-group-grid').innerHTML=groups.map((members,i)=>`<article class="demo-group" style="--group-color:${['#e1f1ff','#eee2ff','#fff1bb','#e5f4eb'][i%4]}"><header><b>${i+1}</b><strong>第${i+1}组</strong><small>${members.length} 人</small></header><div>${members.map(person=>`<span class="demo-name-tag" data-person="${person.i}" style="visibility:hidden">${esc(person.name)}</span>`).join('')}</div></article>`).join('');
        stage.classList.add('is-dealing');$('.demo-group-caption').textContent='先洗洗牌，再认识新的伙伴';
        await Promise.all([...stage.querySelectorAll('.demo-deck-stack>span')].map((node,i)=>move(node,[{transform:'rotate(0deg)'},{transform:`translateX(${i?-35:35}px) rotate(${i?-12:12}deg)`,offset:.45},{transform:'rotate(0deg)'}],800)));
        const origin=$('.demo-deck').getBoundingClientRect(),bounds=stage.getBoundingClientRect();
        $('.demo-group-caption').textContent='正在把姓名牌，轻轻送到每一组';
        await Promise.all(shuffled.map(async(person,i)=>{
          const tag=stage.querySelector(`[data-person="${person.i}"]`),target=tag.getBoundingClientRect();
          const fly=document.createElement('span');fly.className='demo-name-tag demo-flight';fly.textContent=person.name;stage.append(fly);
          fly.style.cssText=`left:${origin.left-bounds.left+origin.width/2-target.width/2}px;top:${origin.top-bounds.top}px;width:${target.width}px;opacity:0`;
          await move(fly,[{opacity:0},{opacity:0}],i*65+1,'linear');
          await move(fly,[{opacity:1,transform:'translate(0,0) rotate(-7deg)'},{opacity:1,transform:`translate(${target.left-origin.left-origin.width/2+target.width/2}px,${target.top-origin.top}px) rotate(0deg)`}],480);
          tag.style.visibility='';fly.remove();
        }));
        $('.demo-deck-stack').remove();stage.classList.remove('is-dealing');$('.demo-group-caption').textContent=`分组完成 · ${state.items.length} 人已分配`;
        text=`分组完成 · ${groups.map(group=>group.length).join(' / ')} 人`;hint='人数均衡，每人只出现一次';
      } else {
        chosen=choose(kind==='die'?6:2);text=kind==='die'?String(chosen+1):chosen===0?'正面':'反面';
        const body=$(kind==='die'?'.demo-cube':'.demo-toss>.demo-coin'),duration=kind==='die'?1900:1800;
        const end=kind==='die'?`rotateX(720deg) rotateY(1080deg) ${diePose(chosen)}`:`rotateX(-12deg) rotateY(${1800+chosen*180}deg)`;
        await Promise.all([
          move(body,[{transform:kind==='die'?diePose(3):'rotateX(-12deg) rotateY(0deg)'},{transform:end}],duration),
          move($('.demo-toss'),[{transform:'translateY(0) scale(1)'},{transform:'translateY(-94px) scale(1)',offset:.4},{transform:'translateY(20px) scale(1.06,.9)',offset:.76},{transform:'translateY(-10px) scale(1)',offset:.87},{transform:'translateY(0) scale(1)'}],duration,'linear'),
          move($('.demo-shadow'),[{transform:'scale(1)',opacity:.18},{transform:'scale(.5)',opacity:.06,offset:.4},{transform:'scale(1.12)',opacity:.25,offset:.76},{transform:'scale(1)',opacity:.18}],duration,'linear')
        ]);
        $('.demo-scene-status').textContent=kind==='die'?`已经停稳啦，本次 ${text} 点`:`硬币落下了，本次为${text}`;
        hint=kind==='die'?'点击投掷，等待骰子停稳':'跳起，翻转，等它轻轻落下';
      }
      if(disposed)return;
      if(round)state.used.push(chosen);
      state.last={text,hint};state.scene=stage.innerHTML;persist();
      if(result)result.textContent=text;
      $('.demo-play span').textContent=info[3];$('.demo-hint').textContent=hint;updateRound();
    }catch(error){if(!disposed){$('.demo-hint').textContent='播放失败，请重试';console.error(error);}}
    finally{if(!disposed)lock(false);}
  }
  $('.demo-play').addEventListener('click',play);
  $('[data-back]').addEventListener('click',()=>host.closest('dialog')?.close());
  $('[data-favorite]').addEventListener('click',()=>{state.favorite=!state.favorite;settings();persist();});
  $('[data-reset]')?.addEventListener('click',()=>{state.used=[];state.last=null;state.scene=null;persist();renderIdle();});
  host.querySelectorAll('[data-repeat]').forEach(el=>el.addEventListener('click',()=>{state.repeat=el.dataset.repeat==='true';settings();persist();}));
  host.querySelectorAll('[data-mode]').forEach(el=>el.addEventListener('click',()=>{state.groupMode=el.dataset.mode;state.scene=null;state.last=null;settings();persist();renderIdle();}));
  for(const [selector,delta]of [['[data-minus]',-1],['[data-plus]',1]])$(selector)?.addEventListener('click',()=>{state.amount=Math.max(1,Math.min(state.items.length,state.amount+delta));state.last=null;state.scene=null;persist();renderIdle();});
  $('[data-edit]')?.addEventListener('click',()=>{$('.demo-editor').hidden=false;$('.demo-editor textarea').value=state.items.join('\n');$('.demo-editor textarea').focus();});
  $('[data-edit-cancel]').addEventListener('click',()=>{$('.demo-editor').hidden=true;$('[data-edit]').focus();});
  $('.demo-editor').addEventListener('submit',event=>{event.preventDefault();const items=$('.demo-editor textarea').value.split('\n').map(v=>v.trim()).filter(Boolean);if(!items.length)return;state.items=items;state.used=[];state.last=null;state.scene=null;state.amount=Math.min(state.amount,items.length);$('[data-count]').textContent=items.length;$('.demo-editor').hidden=true;persist();renderIdle();$('[data-edit]').focus();});
  renderIdle();
  return ()=>{disposed=true;animations.forEach(a=>a.cancel());animations.clear();};
};
