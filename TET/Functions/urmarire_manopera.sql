--***
create function [dbo].[urmarire_manopera] (@datajos datetime,@datasus datetime,@ord int,@inchise int,@simulare int,@com char(20),@sircom char(50),@reper char(20),@lm char(20),@oper char(20),@marca char(20),@evidreal int,@datajosr datetime,@datasusr datetime,@tipl int,@sub char(20))
  returns @tabelManopera table(comanda char(20),dencom char(30),tip_doc char(5),reper char(20),cantnec char(20),lm char(20),nrfisa char(20),pret char(20),datalans datetime,locm_sau_nimic char(30),nimic_sau_locm char(30),xxx char(30),codop char(20),nr_op char(20),tutil char(20),executant char(20),ordonare char(50),denreper char(30),denop char(30),umreper char(20),denexec char(30),denlm char(30),pret1 char(30),cantlans char(30))  
as  
begin   
    declare @nfetch int
    declare @com1 char(20),@dencom1 char(30),@tip1 char(5),@rep1 char(20),@cantn1 char(20)
    declare @lm1 char(20),@fisa1 char(20),@pret1 char(20),@datal1 datetime,@lmn1 char(30)
    declare @nlm1 char(30),@xxx1 char(30),@codop1 char(20),@nrop1 char(20),@tutil1 char(20)
    declare @exec1 char(20),@ord1 char(50),@denrep1 char(30),@denop1 char(30),@um1 char(20)
    declare @denexec1 char(30),@denlm1 char(30),@pret2 char(30),@cantl1 char(30) 
     
    declare tmp cursor for   
   SELECT a.comanda as comanda, b.descriere as dencom, 
     'LM' as tip_doc, a.cod_tata as reper, a.cantitate_necesara as cantnec,
     rtrim(a.loc_de_munca) as lm, a.numar_fisa as nrfisa, a.pret as pret, b.data_lansarii as datalans,
     (CASE WHEN @ord=1 THEN rtrim(a.loc_de_munca) ELSE '' END) as locm_sau_nimic,
     (CASE WHEN @ord=2 THEN rtrim(a.loc_de_munca) ELSE '' END) as nimic_sau_locm, ' ' as xxx,
     a.cod_operatie as codop,  (CASE WHEN 0=0 or (SELECT val_logica FROM par WHERE tip_parametru='SP' and parametru='clagirom')=1 THEN a.numar_operatie ELSE 0 END) as nr_op,
     c.timp_util as tutil, space(6) as executant, (CASE WHEN @ord=1 THEN rtrim(a.loc_de_munca)+a.comanda ELSE a.comanda+rtrim(a.loc_de_munca) END) as ordonare,
       (SELECT denumire FROM tehn WHERE a.cod_tata=cod_tehn) as denreper, (SELECT denumire FROM catop WHERE cod=a.cod_operatie) as denop,
       space(3) as umreper, space(6) as denexec,
       (SELECT denumire FROM lm WHERE a.loc_de_munca=cod) as denlm,  c.tarif_unitar as pret1,' ' as cantlans
  FROM lansman a, comenzi b, tehnpoz c WHERE a.subunitate=b.subunitate
    and a.comanda=b.comanda and (@inchise=1 or b.starea_comenzii<>'I') 
    and (@simulare=1 or b.starea_comenzii<>'S') and (b.data_lansarii between @datajos and @datasus)
    and c.tip='O' and c.cod_tehn=a.cod_tata and c.nr=a.numar_operatie 
    and (@com is null or a.comanda=@com) 
    and (@sircom is null or charindex(','+rtrim(a.comanda)+',',@sircom)>0)
    and (@reper is null or a.cod_tata=@reper) 
    and (@lm is null or a.loc_de_munca like rtrim(@lm)+'%') 
    and (@oper is null or a.cod_operatie=@oper) 
    and (@marca is null or a.numar_fisa in
     (SELECT r.numar_document FROM realcom r WHERE @evidreal=1 and (@com is null or r.comanda=@com) 
    and (@sircom is null or charindex(','+rtrim(r.comanda)+',',@sircom)>0) 
    and (@reper is null or r.cod_reper=@reper) and (@lm is null or r.loc_de_munca like rtrim(@lm)+'%')
    and r.marca=@marca and r.data between @datajosr and @datasusr))
  union all 
    SELECT a.comanda, b.descriere as dencom,
     'RM' as tip_doc, a.cod_reper, 
    (CASE WHEN (SELECT val_logica FROM par WHERE tip_parametru='sp' and parametru='novamodul')=1 THEN c.cantitate ELSE a.cantitate end), 
    LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)),
    LEFT(a.numar_document,8),(case WHEN 0=9 THEN a.norma_de_timp ELSE a.tarif_unitar end),a.data, 
    (case WHEN @ord=1 THEN LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)) ELSE '' end),
    (case WHEN @ord=2 THEN LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)) ELSE '' end),
    right(rtrim(a.loc_de_munca),1), a.cod, 
    (case WHEN 0=0 or (SELECT val_logica FROM par WHERE tip_parametru='SP' and parametru='clagirom')=1 THEN c.numar_operatie ELSE 0 end),
    a.norma_de_timp, a.marca, (case WHEN @ord=1 THEN LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end))+ a.comanda ELSE a.comanda+LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)) end),
      (SELECT denumire FROM tehn WHERE a.cod_reper=cod_tehn) as denreper, (SELECT denumire FROM catop WHERE cod=a.cod) as denop,
               space(3) as umreper, (SELECT nume FROM personal WHERE personal.marca=a.marca),
               (SELECT denumire FROM lm WHERE a.loc_de_munca=cod) as denlm, a.tarif_unitar,' '
  FROM realcom a LEFT outer JOIN comenzi b on a.comanda=b.comanda LEFT outer JOIN realrep c
    on LEFT(a.numar_document,8)=c.numar_fisa and a.data=c.data and
   ((SELECT syscolumns.length FROM syscolumns,sysobjects WHERE sysobjects.name='realcom' and sysobjects.id=syscolumns.id and syscolumns.name='Numar_document')=8 or substring(a.numar_document,13,6)=c.ora_inceput)
   WHERE @tipl=1 and @evidreal=1 and b.subunitate=@sub 
    and (@inchise=1 or b.starea_comenzii<>'I') and (@simulare=1 or b.starea_comenzii<>'S')
    and (b.data_lansarii between @datajos and @datasus) and (@com is null or a.comanda=@com)
    and (@sircom is null or charindex(','+rtrim(a.comanda)+',',@sircom)>0)
    and (@reper is null or a.cod_reper=@reper) and (@lm is null or a.loc_de_munca like rtrim(@lm)+'%')
    and (@marca is null or a.marca=@marca) and a.data between @datajosr and @datasusr
    and (@oper is null or c.cod_operatie=@oper) 
  union all 
  SELECT a.comanda, b.descriere as dencom,
    'RM' as tip_doc, a.cod_reper,a.cantitate, LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)),
    a.numar_fisa, (case WHEN 9=0 THEN (SELECT max((case WHEN 0=9 THEN z.norma_de_timp ELSE z.tarif_unitar end)) 
       FROM realcom z WHERE LEFT(z.numar_document,8)=a.numar_fisa and a.data= z.data and 
       ((SELECT syscolumns.length FROM syscolumns,sysobjects WHERE sysobjects.name='realcom' and sysobjects.id=syscolumns.id and syscolumns.name='Numar_document' )=8 or substring(z.numar_document,13,6)=a.ora_inceput)) ELSE c.pret end),  a.data, 
   (case WHEN @ord=1 THEN LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)) ELSE '' end), 
   (case WHEN @ord=2 THEN LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)) ELSE '' end),
   right(rtrim(a.loc_de_munca),1), a.cod_operatie, 
   (case WHEN 0=0 or (SELECT val_logica FROM par WHERE tip_parametru='SP' and parametru='clagirom')=1 THEN a.numar_operatie ELSE 0 end),
   (SELECT max(y.norma_de_timp) FROM realcom y WHERE LEFT(y.numar_document,8)=a.numar_fisa and a.data=y.data and 
   ((SELECT syscolumns.length FROM syscolumns,sysobjects WHERE sysobjects.name='realcom' and sysobjects.id=syscolumns.id and syscolumns.name='Numar_document' )=8 or substring(y.numar_document,13,6)=a.ora_inceput)), ' ',
   (case WHEN @ord=1 THEN  LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end))+ a.comanda ELSE a.comanda+LEFT(a.loc_de_munca,len(rtrim(a.loc_de_munca))-(case WHEN a.loc_de_munca='' or 1=1 THEN 0 ELSE 1 end)) end),
     (SELECT denumire FROM tehn WHERE a.cod_reper=cod_tehn) as denreper, (SELECT denumire FROM catop WHERE cod=a.cod_operatie) as denop,
            space(3) as umreper,'',
            (SELECT denumire FROM lm WHERE a.loc_de_munca=cod) as denlm,   (SELECT max(y.tarif_unitar) FROM realcom y WHERE LEFT(y.numar_document,8)=a.numar_fisa and a.data=y.data and 
                ((SELECT syscolumns.length FROM syscolumns,sysobjects WHERE sysobjects.name='realcom' and sysobjects.id=syscolumns.id and syscolumns.name='Numar_document' )=8 or                     substring(y.numar_document,13,6)=a.ora_inceput)), ' '
  FROM realrep a LEFT outer JOIN comenzi b on a.comanda=b.comanda LEFT outer JOIN lansman c
   on a.comanda= c.comanda and a.numar_fisa= c.numar_fisa WHERE @tipl=2
   and @evidreal=1 and b.subunitate=@sub and (@inchise=1 or b.starea_comenzii<>'I')
   and (@simulare=1 or b.starea_comenzii<>'S') and (b.data_lansarii between @datajos and @datasus)
   and (@com is null or a.comanda=@com) 
   and (@sircom is null or charindex(','+rtrim(a.comanda)+',',@sircom)>0)
   and (@reper is null or a.cod_reper=@reper)
   and (@lm is null or a.loc_de_munca like rtrim(@lm)+'%')
   and (@marca is null or a.numar_fisa in (SELECT LEFT(x.numar_document,8) FROM realcom x WHERE LEFT(x.numar_document,8)=a.numar_fisa and a.data= x.data 
   and ((SELECT syscolumns.length FROM syscolumns,sysobjects WHERE sysobjects.name='realcom' and sysobjects.id=syscolumns.id and syscolumns.name='Numar_document' )=8 or substring(x.numar_document,13,6)=a.ora_inceput) and x.marca=@marca))
   and a.data between @datajosr and @datasusr and (@oper is null or a.cod_operatie=@oper) 
  ORDER BY lm,comanda,reper,nr_op
    open tmp
    fetch next FROM tmp into @com1,@dencom1,@tip1,@rep1,@cantn1,@lm1,@fisa1,@pret1,@datal1,@lmn1,@nlm1,@xxx1,@codop1,@nrop1,@tutil1,@exec1,@ord1,@denrep1,@denop1,@um1,@denexec1,@denlm1,@pret2,@cantl1
    set @nfetch = @@fetch_status
 while @nfetch = 0
 begin
       INSERT into @tabelManopera values(@com1,@dencom1,@tip1,@rep1,@cantn1,@lm1,@fisa1,@pret1,@datal1,@lmn1,@nlm1,@xxx1,@codop1,@nrop1,@tutil1,@exec1,@ord1,@denrep1,@denop1,@um1,@denexec1,@denlm1,@pret2,@cantl1)  
       fetch next FROM tmp into @com1,@dencom1,@tip1,@rep1,@cantn1,@lm1,@fisa1,@pret1,@datal1,@lmn1,@nlm1,@xxx1,@codop1,@nrop1,@tutil1,@exec1,@ord1,@denrep1,@denop1,@um1,@denexec1,@denlm1,@pret2,@cantl1
    set @nfetch = @@fetch_status
 end
    close tmp
 deallocate tmp
    return
end
