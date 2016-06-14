--***  
create trigger docfac on pozdoc for update,insert,delete as  
begin  
------------- din tabela par (parametri trimis de Magic):  
--(8)  [IF (FK,FL,2)], [IF (FO,FP,2)], FV, GC, HA, [HM OR HL], HN, HO  
 declare @rotunj_n int, @rotunjr_n int, @timbrulit int, @factbil int, @stoehr int, @spgenisaVunicarm int, @docpesch_n int  
 set @rotunj_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJ' and val_logica=1),2)  
 set @rotunjr_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJR' and val_logica=1),2)  
 set @timbrulit=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='TIMBRULIT'),0)  
 set @factbil=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='FACTBIL'),0)  
 set @stoehr=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='STOEHR'),0)  
 set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='GENISA'),0)  
  if (@spgenisaVunicarm=0) set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='UNICARM'),0)  
 set @docpesch_n=(case isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCPESCH'),0) when 1 then 0 else 1 end)  
  if (@docpesch_n=0) set @docpesch_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='DOCPESCH'),0)  
  -- sau "val_logica=0 or val_numerica=1" in loc de "@docpesch_n=1" mai jos  
-------------  
delete from facturi where Subunitate in ('INTRASTAT','EXPAND')  
insert into facturi   
select subunitate,max(loc_de_munca),(case when tip in ('AP','AS') then 0x46 else 0x54 end),factura,tert,  
 max(data_facturii),max(data_scadentei),0,0,0,max(valuta),max(curs),0,0,0,max(cont_factura),0,0,max(comanda),max(data_facturii)   
from inserted   
where tip in ('RM','RP','RQ','RS','AP','AS') and factura not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert and tip=(case when inserted.tip in ('AP','AS') then 0x46 else 0x54 end))  
 and ((cont_factura<>'' or left(cont_de_stoc,1)<>'8' or @factbil=1 and cont_factura=''))   
 and Subunitate not in ('INTRASTAT','EXPAND')  
group by subunitate,(case when tip in ('AP','AS') then 0x46 else 0x54 end),tert,factura  
  
declare @Valoare float,@Tva float,@Tva9 float,@valoarev float,@contF char(13),@gvaluta char(3),@gcurs float,@glocm char(9),@gcom char(40)  
declare @csub char(9),@ctip char(2),@ctert char(13),@cfactura char(20),@semn int,@tvad float,@cant float,@valuta char(3),  
 @curs float,@pstoc float,@pval float,@pvanz float,@cota float,@disc float,@cont char(13),@dvi char(8),  
 @df datetime,@ds datetime,@LME float,@locm char(9),@com char(40),@TVAv float,@dfTVA int,@cuTVA int  
declare @gsub char(9),@gtip char(2),@gtert char(13),@gfactura char(20),@gdf datetime,@gds datetime,@tipf binary,@gfetch int  
  
declare tmp cursor for  
select subunitate,tip,tert,factura,1,tva_deductibil,cantitate,valuta,curs,pret_de_stoc,pret_valuta-(case when tip in ('RM','RS') and @timbrulit=1 and numar_dvi='' then accize_cumparare else 0 end),(case when 1=0 and left(cont_de_stoc,1)='8' and not (tip='
AP' and @factbil=1) then pret_de_stoc else pret_vanzare end),cota_tva,discount,(case when 1=0 and tip='AP' and cont_de_stoc like '8%' and @factbil=0 then '' else cont_factura end),numar_DVI,data_facturii,data_scadentei,suprataxe_vama,loc_de_munca,comanda,
(case when isnumeric(grupa)=1 then convert(float,grupa) else 0 end),procent_vama  
from inserted where tip in ('RM','RP','RQ','RS','AP','AS') and ((cont_factura<>'' or left(cont_de_stoc,1)<>'8' or @factbil=1 and cont_factura=''))   
union all  
select subunitate,tip,tert,factura,-1,tva_deductibil,cantitate,valuta,curs,pret_de_stoc,pret_valuta-(case when tip in ('RM','RS') and @timbrulit=1 and numar_dvi='' then accize_cumparare else 0 end),(case when 1=0 and left(cont_de_stoc,1)='8' and not (tip=
'AP' and @factbil=1) then pret_de_stoc else pret_vanzare end),cota_tva,discount,(case when 1=0 and tip='AP' and cont_de_stoc like '8%' and @factbil=0 then '' else cont_factura end),numar_DVI,data_facturii,data_scadentei,suprataxe_vama,loc_de_munca,comanda
,(case when isnumeric(grupa)=1 then convert(float,grupa) else 0 end),procent_vama  
from deleted where tip in ('RM','RP','RQ','RS','AP','AS') and ((cont_factura<>'' or left(cont_de_stoc,1)<>'8' or @factbil=1 and cont_factura=''))   
order by subunitate,tip,tert,factura  
  
open tmp  
fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@tvad,@cant,@valuta,@curs,@pstoc,@pval,@pvanz,@cota,@disc,@cont,@dvi,@df,@ds,@LME,@locm,@com,@TVAv,@dfTVA  
set @gsub=@csub  
set @gtert=@ctert  
set @gfactura=@cfactura  
set @gtip=@ctip  
set @gfetch=@@fetch_status  
while @gfetch=0  
begin  
 set @Valoare=0  
 set @Tva=0  
 set @Tva9=0  
 set @valoarev=0  
 set @ContF=@cont  
 set @gvaluta=@valuta  
 set @gcurs=@curs  
 set @gdf=@df  
 set @gds=@ds  
 set @glocm=@locm  
 set @gcom=@com  
 while @gsub=@csub and @cTip=@gTip and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0  
 begin  
  if @ctip in ('RM','RP','RQ','RS')  
  begin    
   set @tipf=0x54  
   set @cuTVA=(case when (@ctip='RM' and @dvi<>'') or (@ctip='RM' and @dvi='' or @ctip in ('RP','RS')) and @dfTVA in (1) then 0 else 1 end)  
   set @tva9=@tva9+(case when @cota in (9,11) then @semn*@cuTVA*@tvad else 0 end)  
   set @tva=@tva+(case when @cota not in (9,11) then @semn*@cuTVA*@tvad else 0 end)  
   set @disc=(case when abs(@disc+@cota*100/(@cota+100))<0.01 then convert(decimal(12,4),-@cota*100/(@cota+100))   
    else convert(decimal(12,4),@disc) end)  
   if @valuta=''   
    set @valoare=@valoare+@semn*round(convert(decimal(17,5),@cant*round(@pval*(1+@disc/100),5)),@rotunjr_n)  
   else  
   begin  
    if @dvi='' set @valoare=@valoare+@semn*(case when @ctip='RP' then @pval else round(convert(decimal(17,5),@cant*round(convert(decimal(16,5),@pval*@curs*(1+@disc/100)),5)),@rotunjr_n) end)  
    else set @valoare=@valoare+@semn*(case when @ctip='RP' then @pval when @ctip='RM' and @stoehr=1 and @df>='06/01/2003' then @pstoc*@cant else round(convert(decimal(17,5),@cant*round(convert(decimal(16,5),@pval*@curs),5)),@rotunjr_n) end)  
    set @valoarev=@valoarev+@semn*round(convert(decimal(17,5),@cant*(case when @ctip='RP' then @pstoc else @pval end)*(1+(case when @ctip='RS' or @dvi='' then @disc else 0 end)/100)),2)  
    set @valoarev=@valoarev+@semn*@cuTVA*@TVAv  
   end  
  end  
  else begin  
   set @tipf=0x46  
   set @cuTVA=(case when @ctip in ('AP','AS') and @dfTVA in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or @ctip='AS') then 0 else 1 end)  
   set @tva9=@tva9+(case when @cota in (9,11) then @semn*@cuTVA*@tvad else 0 end)  
   set @tva=@tva+(case when @cota not in (9,11) then @semn*@cuTVA*@tvad else 0 end)  
   set @valoare=@valoare+@semn*round(convert(decimal(17,5),@cant*@pvanz),@rotunj_n)  
   if @valuta<>'' begin  
    set @valoarev=@valoarev+@semn*round(convert(decimal(17,5),@cant*(@pval*(1-@disc/100)+@LME/1000))+(case when @curs>0 then @cuTVA*@tvad/@curs else 0 end),2)  
   end  
  end  
  if @semn=1 set @contF=@cont  
  if @semn=1 set @gvaluta=@valuta  
  if @semn=1 set @gcurs=@curs  
  if @semn=1 set @gdf=@df  
  if @semn=1 set @gds=@ds  
  if @semn=1 set @glocm=@locm  
  if @semn=1 set @gcom=@com  
  
  fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@tvad,@cant,@valuta,@curs,@pstoc,@pval,@pvanz,@cota,@disc,@cont,@dvi,@df,@ds,@LME,@locm,@com,@TVAv,@dfTVA  
  set @gfetch=@@fetch_status  
 end   
  
 if @tipf=0x46 --Ghita, 09.07.2012: Verificare sold maxim beneficiar  
 begin   
   
  declare @valFactura float, @soldmaxim float, @sold float, @zileScadDepasite bit  
    
  select @valFactura = @valoare+@tva+@tva9   
    
  if @valFactura > 0.001  
  begin  
   declare @xml xml  
   set @xml=(select @gtert tert for xml raw)  
   exec wIaSoldTert @sesiune='', @parXML=@xml output  
     
   -- procedura returneaza null daca nu trebuie validat soldul  
   if @xml is not null  
   begin   
    declare @msgErr varchar(500)  
    select @sold=@xml.value('(/row/@sold)[1]','float'),  
      @soldmaxim=@xml.value('(/row/@soldmaxim)[1]','float'),  
      @zileScadDepasite= @xml.value('(/row/@zilescadentadepasite)[1]','bit')  
      
    if @zileScadDepasite=1  
     set @msgErr = isnull(@msgErr+CHAR(13),'')+'Tertul are facturi cu scadenta depasita.'  
      
    if @xml.value('(/row/@soldmaxim)[1]','float') is not null and @sold+@valFactura>@soldmaxim  
     set @msgErr = isnull(@msgErr+CHAR(13),'')+'Generarea facturii ar cauza depasirea soldului maxim pentru acest tert.'  
      +CHAR(13)+ 'Soldul maxim permis este '+ CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'  
      +CHAR(13)+ 'Soldul anterior este '+ CONVERT(varchar(30), convert(decimal(12,2), @sold)) + ' RON.'  
      +CHAR(13)+ 'Valoarea pozitiei (modificarii) curente '+ CONVERT(varchar(30), convert(decimal(12,2), @valFactura)) + ' RON.'  
      
    if len(@msgErr)>0  
    begin  
     rollback transaction  
     raiserror(@msgErr,11,1)  
    end  
   end  
  end  
 end  
   
 update facturi set valoare=valoare+@valoare,tva_22=tva_22+@tva,tva_11=tva_11+@tva9,  
  sold=sold+@valoare+@tva+@tva9,  
  valuta='',curs=0,  
  cont_de_tert=@contF,loc_de_munca=@glocm,comanda=@gcom,  
  data=(case when data>@gdf then @gdf else data end),data_scadentei=(case when data_scadentei>@gds then @gds else data_scadentei end)  
 where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura  
  
 update facturi set valoare_valuta=valoare_valuta+@valoarev,sold_valuta=sold_valuta+@valoarev,  
  valuta=@gvaluta,curs=@gcurs   
 from terti where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura  
  and facturi.subunitate=terti.subunitate and facturi.tert=terti.tert and terti.tert_extern=1   
  
 set @gtert=@ctert  
 set @gsub=@csub  
 set @gfactura=@cfactura  
 set @gtip=@ctip  
end  
close tmp  
deallocate tmp  
end  