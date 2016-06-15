--***
create procedure pregbun(@DataJos datetime,@DataSus datetime,@tert char(13),@cod_material char(20)) as  
begin  
  
 declare @subunitate char(9),@numar char(8),@comanda char(40),@cod char(20),@cantitate float  
 select distinct rm.data as data_primirii  
   ,t.denumire as denumire_tert,t.adresa,rm.tert as tert,t.cod_fiscal  
   ,n.denumire as denumire_bun  
   ,rm.cod as cod_bun,rm.cantitate as cantitate_bun,rm.pret_de_stoc*rm.cantitate as valoare_bun  
   ,cm.comanda,rm.cod_intrare,rm.subunitate into #cursrmcmrb  
   from pozdoc rm ,pozdoc cm, terti t,nomencl n  
   where rm.tip='RM' and cm.tip='CM' and cm.cod_intrare=rm.cod_intrare and cm.subunitate=rm.subunitate   
    and rm.comanda<>'' and n.cod=rm.cod and t.tert=rm.tert  
    and rm.data between @DataJos and @DataSus and (rtrim(rm.tert)=rtrim(@tert) or rtrim(@tert)='')   
    and (rtrim(@cod_material)=rtrim(rm.cod) or rtrim(@cod_material)='')  
  
 select distinct n.denumire as denumire_ret, ap.cod as cod_bun_ret ,0 as pondere  
    ,ap.pret_de_stoc as valoare_ret,ap.subunitate,ap.comanda,ap.cod_intrare,ap.numar  
    ,identity(int) as numar_ordine,  
    ap.cantitate as ap_cantitate,0 as cm_cantitate,ap.tert,ap.data as data_ap  
  into #cursappcmrb  
  from pozdoc ap,nomencl n
  where ap.tip='AP' and comanda<>'' and n.cod=ap.cod  
  
 declare c1 cursor for  
 select comanda,subunitate,cod_bun_ret from #cursappcmrb  
 open c1  
 fetch next from c1 into @comanda,@subunitate,@cod  
 while @@fetch_status=0  
 begin  
  update #cursappcmrb set pondere=  
   isnull((select sum(cantitate) from pozcom pz where @comanda=pz.comanda and @subunitate=pz.subunitate and   
    @cod=pz.cod_produs)/(case when #cursappcmrb.ap_cantitate=0 then 1 else #cursappcmrb.ap_cantitate end),0)  
   ,cm_cantitate=isnull((select sum(cantitate) from pozcom pz where @comanda=pz.comanda   
    and @subunitate=pz.subunitate and @cod=pz.cod_produs),0)  
    where comanda=@comanda and subunitate=@subunitate and cod_bun_ret=@cod   
  fetch next from c1 into @comanda,@subunitate,@cod  
 end  
 close c1  
 deallocate c1  
 if not exists(select * from sysobjects where name='regbunuri'and xtype='u')  
 select convert(datetime,unu.data_primirii) as data_primirii, unu.denumire_tert, unu.adresa, unu.tert, unu.cod_fiscal,   
   unu.denumire_bun, unu.cod_bun, unu.cantitate_bun,unu.valoare_bun,'' as denumire_ret,'' as cod_bun_ret  
   ,doi.cm_cantitate as cantitate_ret,unu.valoare_bun*doi.pondere as valoare_ret,convert(datetime,doi.data_ap) as data_tr  
   ,'Invoice' as denumire_serv,doi.numar_ordine as nr_ordine,convert(datetime,doi.data_ap)  as data_serviciu   
  into regbunuri   
  from #cursrmcmrb unu,#cursappcmrb doi   
  where unu.comanda=doi.comanda and unu.subunitate=doi.subunitate and unu.tert=doi.tert   
    and unu.data_primirii between @DataJos and @DataSus and (rtrim(unu.tert)=rtrim(@tert) or rtrim(@tert)='')   
    and (rtrim(@cod_material)=rtrim(unu.cod_bun) or rtrim(@cod_material)='')  
 else  
 begin  
 delete from regbunuri where data_primirii between @DataJos and @DataSus and (rtrim(tert)=rtrim(@tert) or rtrim(@tert)='')  
    and (rtrim(@cod_material)=rtrim(cod_bun) or rtrim(@cod_material)='')  
 insert into regbunuri (Data_primirii,Denumire_tert,Adresa,Tert,Cod_fiscal,Denumire_bun,Cod_bun,Cantitate_bun,Valoare_bun,
	Denumire_ret,Cod_bun_ret,Cantitate_ret,Valoare_ret,Data_tr,Denumire_serv,Nr_ordine,Data_serviciu)
 select convert(datetime,unu.data_primirii) as data_primirii, unu.denumire_tert, unu.adresa, unu.tert, unu.cod_fiscal,  
   unu.denumire_bun,unu.cod_bun, unu.cantitate_bun,unu.valoare_bun,'' as denumire_ret,'' as cod_bun_ret,  
   doi.cm_cantitate as cantitate_ret,unu.valoare_bun*doi.pondere as valoare_ret  
   ,convert(datetime,doi.data_ap) as data_tr,'Invoice' as denumire_serv  
   ,doi.numar_ordine as nr_ordine,convert(datetime,doi.data_ap)  as data_serviciu   
   from #cursrmcmrb unu,#cursappcmrb doi   
   where unu.comanda=doi.comanda and unu.subunitate=doi.subunitate and unu.tert=doi.tert   
    and unu.data_primirii between @DataJos and @DataSus and (rtrim(unu.tert)=rtrim(@tert) or rtrim(@tert)='')   
    and (rtrim(@cod_material)=rtrim(unu.cod_bun) or rtrim(@cod_material)='')  
 end  
 drop table #cursappcmrb  
 drop table #cursrmcmrb  
end
