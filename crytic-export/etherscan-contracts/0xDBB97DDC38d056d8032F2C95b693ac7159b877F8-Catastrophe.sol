// .-. .-. .-. .-. .-. .-. .-. .-. .-. . . .-. 
// |   |-|  |  |-| `-.  |  |(  | | |-' |-| |-  
// `-' ` '  '  ` ' `-'  '  ' ' `-' '   ' ` `-' 
//
// SPDX-License-Identifier: MIT
// Copyright Han, 2023

pragma solidity ^0.8.21;

contract Catastrophe {
    event ArtpieceCreated(address indexed creator);
    event ArtpieceTransferred(address indexed oldOwner, address indexed newOwner);
    event BidAccepted(uint256 value, address indexed fromAddress, address indexed toAddress);
    event BidPlaced(uint256 value, address indexed fromAddress);
    event BidWithdrawn(uint256 value, address indexed fromAddress);
    event ListedForSale(uint256 value, address indexed fromAddress, address indexed toAddress);
    event SaleCanceled(uint256 value, address indexed fromAddress, address indexed toAddress);
    event SaleCompleted(uint256 value, address indexed fromAddress, address indexed toAddress);

    error FundsTransfer();
    error InsufficientFunds();
    error ListedForSaleToSpecificAddress();
    error NoBid();
    error NotForSale();
    error NotOwner();
    error NotRoyaltyRecipient();
    error NotYourBid();
    error NullAddress();
    error RoyaltyTooHigh();

    string public constant MANIFEST = (
        'Cubic limit.' '\n'
    );

    string public constant CORE = (
        '"use strict";const SIGNATURE_SVG="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjUiIGhlaWdodD0iMjMiIHZpZXdCb3g9IjAgMCAyNSAyMyIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0yIDBIMVYxSDJIM1YwSDJaTTUgMEg2SDdWMUg2SDVWMFpNOSAwSDEwSDExSDEySDEzVjFIMTJIMTFIMTBIOVYwWk0xNSAwSDE2SDE3VjFIMTZWMkgxNUgxNFYxSDE1VjBaTTE5IDBIMjBIMjFWMUgyMlYySDIxSDIwVjFIMTlWMFpNMjQgMUgyNVYyVjNWNFY1SDI0VjRWM1YyVjFaTTQgMkgzVjNWNEg0VjNWMlpNMyA2SDRWN1Y4SDNWN1Y2Wk0yNCA3SDI1VjhWOUgyNFY4VjdaTTEyIDlIMTNWMTBIMTJWOVpNMTUgOUgxNFYxMEgxNVY5Wk0zIDEwSDRWMTFWMTJWMTNIM1YxMlYxMVYxMFpNMyAxM1YxNEgyVjEzSDNaTTEyIDExSDEzVjEySDEyVjExWk0xNSAxMUgxNFYxMkgxNVYxMVpNMjQgMTFIMjVWMTJWMTNWMTRIMjRWMTNWMTJWMTFaTTMgMTZIMlYxN0gxVjE4VjE5VjIwSDBWMjFIMUgyVjIwVjE5VjE4VjE3SDNWMTZaTTI0IDE2SDI1VjE3VjE4VjE5SDI0VjE4VjE3VjE2Wk0yMyAyMVYyMFYxOUgyNFYyMFYyMUgyM1pNMjMgMjJWMjFIMjJWMjJWMjNIMjNIMjRWMjJIMjNaTTUgMjBINFYyMUg1SDZWMjJIN0g4SDlWMjFIOEg3SDZWMjBINVpNMTIgMjFIMTFWMjJIMTJIMTNIMTRWMjFIMTNIMTJaTTE2IDIxSDE3SDE4SDE5SDIwVjIySDE5SDE4SDE3SDE2VjIxWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cg==",FRAG_DIRECTIVES=["#version 300 es","precision highp float;","const int AA=2;","out vec4 fragColor;","#define R(a)mat2(cos(a),sin(a),-sin(a),cos(a))"].map((e=>`${e}${String.fromCharCode(10)}`)).join(""),VERT_DIRECTIVES=["#version 300 es"].map((e=>`${e}${String.fromCharCode(10)}`)).join("");let frag_shader_string=`${FRAG_DIRECTIVES}uniform vec2 u_resolution,u_mouse;uniform float u_time;float v,r;vec4 f[26];vec2 m=vec2(0);float t(vec3 v,vec3 x){vec3 m=abs(v)-x;return length(max(m,0.))+min(max(max(m.y,m.x),m.z),0.);}vec3 t(vec3 v){v=vec3(dot(v,vec3(127.1,311.7,74.7)),dot(v,vec3(269.5,183.3,246.1)),dot(v,vec3(113.5,271.9,124.6)));return-1.+2.*fract(sin(v)*43758.5453123);}vec3 x(vec3 v){return clamp(v*(2.51*v+.03)/(v*(2.43*v+.59)+.14),0.,1.);}float s(vec3 v){v=fract(v*.3183099+.1);v*=17.;return fract(v.x*v.y*v.z*(v.x+v.y+v.z));}float n(vec3 v){vec3 m=floor(v),f=fract(v);f=f*f*(3.-2.*f);return mix(mix(mix(s(m+vec3(0)),s(m+vec3(1,0,0)),f.x),mix(s(m+vec3(0,1,0)),s(m+vec3(1,1,0)),f.x),f.y),mix(mix(s(m+vec3(0,0,1)),s(m+vec3(1,0,1)),f.x),mix(s(m+vec3(0,1,1)),s(m+vec3(1)),f.x),f.y),f.z);}vec3 i;vec2 p(vec2 v){vec3 m=fract(vec3(v.xyx)*vec3(.1031,.103,.0973));m+=dot(m,m.yzx+33.33);return fract((m.xx+m.yz)*m.zy);}vec2 n(vec3 m,vec2 r){int i=int(r.x+(r.x+1.)*r.y);vec4 n=f[i];float x=n.z,s,y;r=n.xy;vec2 c=vec2(2.*acos(-1.)*v);c.x*=max(r.x*3.,.5);c.y*=max(r.y*3.,.5);m.xy*=R(2.*acos(-1.)*r.x+c.x);m.yz*=R(2.*acos(-1.)*r.y+c.y);m.zx*=R(2.*acos(-1.)*v+2.*acos(-1.)*x);vec3 z=mix(vec3(.25),vec3(.3),x);s=t(m,z);y=t(m-vec3(0,0,z.z*2.-.01),z);y=max(s,y);return vec2(s,y);}vec2 e(vec3 v){float x=1e20,m;vec2 y=round(v.xy),s=sign(v.xy-y);m=1e20;for(int f=0;f<2;f++)for(int r=0;r<2;r++){vec2 z=y+vec2(r,f)*s,c=n(vec3(v.xy-z,v.z),z+vec2(2.5));if(m>c.y)m=c.y,x=2.;if(m>c.x)m=c.x,x=1.;}vec3 f=abs(v)-vec3(vec2(5).xy,1)*.5;return vec2(max(m,min(max(max(f.x,f.y),f.z),0.)+length(max(f,0.))),x);}vec2 w(vec3 v){vec2 f=e(v);return vec2(min(1e2,f.x),f.y);}vec3 c(vec3 v){vec2 f=vec2(.002,0);float m=w(v).x;return normalize(vec3(m-w(v-f.xyy).x,m-w(v-f.yxy).x,m-w(v-f.yyx).x));}vec2 c(vec3 v,vec3 x){float m=0.;vec2 f;for(int r=0;r<64;r++){vec3 y=v+x*m;f=w(y);m+=f.x;if(m>20.||abs(f.x)<.001)break;}m=min(m,20.);return vec2(m,f.y);}vec4 e(vec3 v,vec3 m){vec3 f=c(v),y=vec3(0,2,1.0001),r;y=normalize(v-y);float s=clamp(dot(y,f),0.,1.),x=clamp(1.+dot(m,f),0.,1.),z=clamp(dot(reflect(-y,f),-m),0.,1.);r=mix(vec3(.9),vec3(1)*2.,pow(s,1.));r+=vec3(1)*pow(x,7.);r+=vec3(1)*pow(z,2.)*.75;return vec4(r,x);}vec4 p(vec2 m,vec2 f){vec2 r=(m-.5*f)/min(f.y,f.x),s;vec3 y=vec3(0,0,-10),z,a,A,d,u,k;i=y;z=normalize(vec3(0)-y);a=normalize(vec3(z.z,0,-z.x));A=normalize(r.x*a+r.y*cross(z,a)+z/.56);s=c(y,A);d=y+A*s.x;u=vec3(0);float h=0.,l,p;if(s.x<20.){vec4 t=e(d,A);u=t.xyz;h=mix(1.,0.,step(s.y,1.));}l=smoothstep(3.,10.,length(d));p=n(vec3(r*1e3,v*50.));p=pow(p,.99);k=mix(vec3(.63),vec3(1)*2.,p);u=mix(u,vec3(1.2),l);u=mix(u,k,h);u=x(u);return vec4(u,l);}float d(float v){vec3 m=fract(vec3(v)*443.8975);m+=dot(m,m.yzx+19.19);return fract((m.x+m.y)*m.z);}float h(float v){float m=floor(v);return mix(d(m),d(m+1.),smoothstep(0.,1.,fract(v)));}void c(){m=u_mouse/u_resolution;vec2 v=m*2.;for(float r=0.;r<26.;r++){float y=floor(r/5.),x=mod(r,5.);vec2 s=vec2(y,x);vec4 c=vec4(1);c.xy=p(s)*2.;c.z=n(vec3(s.x+v.x,s.y+v.y,2));f[int(r)]=c;}}vec4 d(vec2 m,vec2 f){c();vec4 y=vec4(0,0,0,1);float x=.5+.5*sin(m.x*147.)*sin(m.y*131.),s=h(u_time*3.);s=pow(s,2.);s=smoothstep(.5,1.,s);for(int z=0;z<AA;z++)for(int u=0;u<AA;u++){float n=u_time-.125*(float(z*AA+u)+x)/float(AA*AA);vec2 d=m+vec2(u,z)/float(AA);v=n/8.;r=2.*acos(-1.)*v;y.xyz+=p(d,f).xyz;}y/=float(AA*AA);return y;}void main(){vec4 v=vec4(1);vec2 m=gl_FragCoord.xy;v=d(m,u_resolution);vec3 y=fract(555.*sin(777.*t(m.xyy)))/256.;fragColor=vec4(v.xyz+y,1);}`,vert_shader_string=`${VERT_DIRECTIVES}in vec2 p;void main(){gl_Position=vec4(p,1.0,1.0);}`;const mouse_sensitivity=1,mouse_limit=0,CREDITS="I am grateful to Dima, WillStall, and IQ (opLimitedRepetition) for making this piece possible, you are wizards. - Han";console.log(CREDITS);let w=window,d=document,b=d.body;d.body.style.touchAction="none",d.body.style.userSelect="none";let c=d.createElement("canvas");c.style.display="block",b.appendChild(c);const mobile=/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),appendSignature=()=>{const e=d.createElement("img");e.src=SIGNATURE_SVG.trim(),e.style.cssText="width:40px;z-index:50;position:fixed;bottom:20px;right:20px;",b.appendChild(e)};let h={},s={};const glOptions={powerPreference:"high-performance"};mobile&&delete glOptions.powerPreference,window.gl=c.getContext("webgl2",glOptions),h.uniform=(e,t)=>{let r=Array.isArray(t)?t.length-1:0,i=[["uniform1f",0,"float"],["uniform2fv",[0,0],"vec2"]],o={};return o.name=e,o.type=i[r][0],o.value=t||i[r][1],o.inner_type=i[r][2],o.location="",o.dirty=!1,o},s.uniforms=[["u_resolution",[0,0]],["u_time",0],["u_mouse",[0,0]]],s.uniforms.forEach(((e,t)=>s.uniforms[t]=h.uniform(e[0],e[1]))),h.resize=()=>{let e=s.uniforms[0],t={x:h.ix.mouse.x/e.value[0],y:h.ix.mouse.y/e.value[1]},r=window.innerWidth,i=window.innerHeight;s.aspect&&(r>i*s.aspect?r=i*s.aspect:i=r/s.aspect);let o=window.devicePixelRatio;e.value[0]=c.width=r*o,e.value[1]=c.height=i*o,c.style.width=r+"px",c.style.height=i+"px",e.dirty=!0,h.ix.set(c.width*t.x,c.height*t.y)},h.ix={start:{x:0,y:0},mouse:{x:0,y:0}},h.ix.save=()=>{let e=s.uniforms[2];e.value=[h.ix.mouse.x,h.ix.mouse.y],e.dirty=!0},h.ix.set=(e,t)=>{h.ix.mouse={x:e,y:t},h.ix.save()},h.ix.start=e=>{h.ix.start.x=e.clientX,h.ix.start.y=e.clientY,d.addEventListener("pointermove",h.ix.move)},h.ix.move=e=>{if(window.changing)return;h.ix.mouse.x+=(e.clientX-h.ix.start.x)*window.devicePixelRatio*mouse_sensitivity,h.ix.mouse.y-=(e.clientY-h.ix.start.y)*window.devicePixelRatio*mouse_sensitivity,h.ix.start.x=e.clientX,h.ix.start.y=e.clientY;let t=s.uniforms[0];h.ix.mouse.x<t.value[0]*mouse_limit&&(h.ix.mouse.x=t.value[0]*mouse_limit),h.ix.mouse.x>t.value[0]*(1-mouse_limit)&&(h.ix.mouse.x=t.value[0]*(1-mouse_limit)),h.ix.mouse.y<t.value[1]*mouse_limit&&(h.ix.mouse.y=t.value[1]*mouse_limit),h.ix.mouse.y>t.value[1]*(1-mouse_limit)&&(h.ix.mouse.y=t.value[1]*(1-mouse_limit)),h.ix.save()},h.ix.stop=()=>{d.removeEventListener("pointermove",h.ix.move)},h.buildShader=(e,t)=>{let r=gl.createShader(e);return gl.shaderSource(r,t),gl.compileShader(r),r},h.initProgram=(e,t)=>{window.program=s.program=gl.createProgram();const r=h.buildShader(gl.VERTEX_SHADER,t),i=h.buildShader(gl.FRAGMENT_SHADER,e);gl.attachShader(s.program,r),gl.attachShader(s.program,i),gl.linkProgram(s.program),gl.getShaderParameter(r,gl.COMPILE_STATUS)||console.error("V: "+gl.getShaderInfoLog(r)),gl.getShaderParameter(i,gl.COMPILE_STATUS)||console.error("F: "+gl.getShaderInfoLog(i)),gl.getProgramParameter(s.program,gl.LINK_STATUS)||console.error("P: "+gl.getProgramInfoLog(s.program));for(let e in s.uniforms){let t=s.uniforms[e];t.location=gl.getUniformLocation(s.program,t.name),t.dirty=!0}let o=Float32Array.of(-1,1,-1,-1,1,1,1,-1),a=gl.createBuffer(),c=gl.getAttribLocation(s.program,"p");gl.bindBuffer(gl.ARRAY_BUFFER,a),gl.bufferData(gl.ARRAY_BUFFER,o,gl.STATIC_DRAW),gl.enableVertexAttribArray(c),gl.vertexAttribPointer(c,2,gl.FLOAT,!1,0,0),gl.useProgram(s.program)},s.pixel=new Uint8Array(4),h.render=()=>{gl.viewport(0,0,c.width,c.height);let e=s.uniforms[1];e.value=.001*performance.now(),e.dirty=!0;let t=s.uniforms.filter((e=>e.dirty));for(let e in t)gl[t[e].type](t[e].location,t[e].value),t[e].dirty=!1;gl.drawArrays(gl.TRIANGLE_STRIP,0,4),gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,s.pixel),requestAnimationFrame(h.render)};const init=async()=>{if(gl){if(mobile){const e="const int AA=2";frag_shader_string=frag_shader_string.replace(e,"const int AA=1")}h.initProgram(frag_shader_string,vert_shader_string),h.resize(),h.ix.set(c.width/2,c.height/2),h.render(),d.addEventListener("pointerdown",h.ix.start),d.addEventListener("pointerup",h.ix.stop),window.addEventListener("resize",h.resize),appendSignature()}else{const e=d.createElement("div");e.style.cssText="align-items:center;background:#969696;color:#fff;display:flex;font-family:monospace;font-size:20px;height:100vh;justify-content:center;left:0;position:fixed;top:0;width:100vw;",e.innerHTML="Your browser does not support WebGL.",b.append(e)}};init();'
    );

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert NotOwner();
        }

        _;
    }

    modifier onlyRoyaltyRecipient() {
        if (royaltyRecipient != msg.sender) {
            revert NotRoyaltyRecipient();
        }

        _;
    }

    struct Offer {
        bool active;
        uint256 value;
        address toAddress;
    }

    struct Bid {
        bool active;
        uint256 value;
        address fromAddress;
    }

    address public owner;

    Offer public currentOffer;

    Bid public currentBid;

    address public royaltyRecipient;

    uint256 public royaltyPercentage;

    mapping (address => uint256) public pendingWithdrawals;

    constructor(uint256 _royaltyPercentage) {
        if (_royaltyPercentage >= 100) {
            revert RoyaltyTooHigh();
        }

        owner = msg.sender;
        royaltyRecipient = msg.sender;
        royaltyPercentage = _royaltyPercentage;

        emit ArtpieceCreated(msg.sender);
    }

    function name() public view virtual returns (string memory) {
        return 'Catastrophe';
    }

    function symbol() public view virtual returns (string memory) {
        return 'C';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'Catastrophe', '</title>'

                    '<meta name="viewport" content="width=device-width, initial-scale=1" />'

                    '<style>html,body{background:#969696;margin:0;padding:0;overflow:hidden;}</style>'
                '</head>'

                '<body>'
                    '<script type="text/javascript">',
                        CORE,
                    '</script>'
                '</body>'
            '</html>'
        );
    }

    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        _sendFunds(amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert NullAddress();
        }

        _transferOwnership(newOwner);

        if (currentBid.fromAddress == newOwner) {
            uint256 amount = currentBid.value;

            currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

            pendingWithdrawals[newOwner] += amount;
        }

        if (currentOffer.active) {
            currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });
        }
    }

    function listForSale(uint256 salePriceInWei) public onlyOwner {
        currentOffer = Offer({ active: true, value: salePriceInWei, toAddress: address(0) });

        emit ListedForSale(salePriceInWei, msg.sender, address(0));
    }

    function listForSaleToAddress(uint256 salePriceInWei, address toAddress) public onlyOwner {
        currentOffer = Offer({ active: true, value: salePriceInWei, toAddress: toAddress });

        emit ListedForSale(salePriceInWei, msg.sender, toAddress);
    }

    function cancelFromSale() public onlyOwner {
        Offer memory oldOffer = currentOffer;

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });

        emit SaleCanceled(oldOffer.value, msg.sender, oldOffer.toAddress);
    }

    function buyNow() public payable {
        if (!currentOffer.active) {
            revert NotForSale();
        }

        if (currentOffer.toAddress != address(0) && currentOffer.toAddress != msg.sender) {
            revert ListedForSaleToSpecificAddress();
        }

        if (msg.value != currentOffer.value) {
            revert InsufficientFunds();
        }

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });

        uint256 royaltyAmount = _calcRoyalty(msg.value);

        pendingWithdrawals[owner] += msg.value - royaltyAmount;
        pendingWithdrawals[royaltyRecipient] += royaltyAmount;

        emit SaleCompleted(msg.value, owner, msg.sender);

        _transferOwnership(msg.sender);
    }

    function placeBid() public payable {
        if (msg.value <= currentBid.value) {
            revert InsufficientFunds();
        }

        if (currentBid.value > 0) {
            pendingWithdrawals[currentBid.fromAddress] += currentBid.value;
        }

        currentBid = Bid({ active: true, value: msg.value, fromAddress: msg.sender });

        emit BidPlaced(msg.value, msg.sender);
    }

    function acceptBid() public onlyOwner {
        if (!currentBid.active) {
            revert NoBid();
        }

        uint256 amount = currentBid.value;
        address bidder = currentBid.fromAddress;

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });
        currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

        uint256 royaltyAmount = _calcRoyalty(amount);

        pendingWithdrawals[owner] += amount - royaltyAmount;
        pendingWithdrawals[royaltyRecipient] += royaltyAmount;

        emit BidAccepted(amount, owner, bidder);

        _transferOwnership(bidder);
    }

    function withdrawBid() public {
        if (msg.sender != currentBid.fromAddress) {
            revert NotYourBid();
        }

        uint256 amount = currentBid.value;

        currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

        _sendFunds(amount);

        emit BidWithdrawn(amount, msg.sender);
    }

    function setRoyaltyRecipient(address newRoyaltyRecipient) public onlyRoyaltyRecipient {
        if (newRoyaltyRecipient == address(0)) {
            revert NullAddress();
        }

        royaltyRecipient = newRoyaltyRecipient;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;

        owner = newOwner;

        emit ArtpieceTransferred(oldOwner, newOwner);
    }

    function _sendFunds(uint256 amount) internal virtual {
        (bool success, ) = msg.sender.call{value: amount}('');

        if (!success) {
            revert FundsTransfer();
        }
    }

    function _calcRoyalty(uint256 amount) internal virtual returns (uint256) {
        return (amount * royaltyPercentage) / 100;
    }
}
