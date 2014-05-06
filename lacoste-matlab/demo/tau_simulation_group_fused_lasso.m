
Tlist=10:10:1000;
Cf=zeros(length(Tlist),1);
for i=1:length(Tlist);
    T=Tlist(i);
    D=-diff(eye(T))';
    H=D'*D;
    t=ones(T-1,1);
    t(1:2:end)=-1;

    Cf(i)=norm(H*t);
end
%%
h=figure(1);
hold off;
plot(Tlist,Cf,'-','linewidth',2,'markersize',12);
hold on;
plot(Tlist,4*sqrt(Tlist),'--r','linewidth',2);
plot(Tlist,Tlist,'-k','linewidth',2);
grid on;
xlabel('\tau','fontsize',16)
h_leg=legend('$1/4\sqrt{C_f^{\tau}}$','$4\sqrt{\tau}$', '$4\tau$');
set(h_leg,'interpreter','latex','fontsize',16,'location','southeast')
ylim([0,140])
set(h,'position',[50,50,400,400])
saveTightFigure(h,'C_f_simulation_flasso.pdf')