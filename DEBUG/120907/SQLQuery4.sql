--***  
create procedure wIaPretDiscount @parXML xml, @Pret float output, @Discount float output  
as  
  
--se sugereaza pret si, respectiv, discount doar daca la intrare fiecare in parte are valoarea null  
/*select @Pret=null, @Discount=null*/  
  
declare @Cod char(20), @Data datetime, @Tert char(13), @ComandaLivrare char(20), @CategPret int,   
 @IauPretAmanunt int, @DocumentInValuta int,   
 @Sb char(9), @TabelaPreturi int, @DiscGrupeContr int, @AnulareDiscount int,   
 @GrupaNom char(13), @TipCategorie int, @CategorieInValuta int, @PretReferinta float, @PretLuatInValuta int  
  
select @Cod=isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),   
 @Data=isnull(@parXML.value('(/row/@data)[1]', 'datetime'), convert(datetime, convert(char(10), getdate(), 101), 101)),   
 @Tert=isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),   
 @ComandaLivrare=isnull(@parXML.value('(/row/@comandalivrare)[1]', 'varchar(20)'), ''),   
 @CategPret=isnull(@parXML.value('(/row/@categpret)[1]', 'int'), 0),   
 @IauPretAmanunt=isnull(@parXML.value('(/row/@iaupretamanunt)[1]', 'int'), 0),   
 @DocumentInValuta=isnull(@parXML.value('(/row/@documentinvaluta)[1]', 'int'), 0)  
  
select @Sb='', @TabelaPreturi=0, @DiscGrupeContr=0  
select @Sb=(case when tip_parametru='GE' and parametru='SUBPRO' then val_alfanumerica else @Sb end),   
 @TabelaPreturi=(case when tip_parametru='GE' and parametru='PRETURI' then convert(int, val_logica) else @TabelaPreturi end),   
 @DiscGrupeContr=(case when tip_parametru='GE' and parametru='CNTRPG' then convert(int, val_logica) else @DiscGrupeContr end)  
from par  
/*tratat pe caz general: Daca exista comanda atunci nu se mai ia pretul din tabelaPreturi ci din comanda*/  
if @ComandaLivrare <> '' set @TabelaPreturi = 0  
select @AnulareDiscount=0, @PretLuatInValuta=0  
  
if (@Pret is null or @Discount is null) and @TabelaPreturi = 0  
begin  
   
 set @GrupaNom=isnull((select max(grupa) from nomencl where @DiscGrupeContr=1 and cod=@Cod), '')  
   
 select @PretLuatInValuta=(case when @Pret is null and p.pret>0 and c.valuta<>'' then 1 else @PretLuatInValuta end),   
  @Pret=(case when @Pret is null and p.pret>0 then   
     p.pret*(case when @IauPretAmanunt=1 then (1+convert(float,p.cota_tva)/100.00) else 1 end)   
     else @Pret end),   
  @Discount=(case when @Discount is null and p.discount<>0 then p.discount else @Discount end)  
 from con c  
 inner join pozcon p on p.subunitate=c.subunitate and p.tip=c.tip and p.contract=c.contract and p.tert=c.tert and p.data=c.data  
 where c.subunitate=@Sb and c.tert=@Tert   
 and (c.tip='BF' and c.stare in ('1', '3') and @Data between c.data and c.termen or @ComandaLivrare<>'' and c.tip='BK' and c.contract=@ComandaLivrare)  
 and (c.tip='BF' and @DiscGrupeContr=1 and @GrupaNom<>'' and left(p.mod_de_plata, 1)='G' and p.cod=@GrupaNom or (c.tip='BK' or rtrim(left(p.mod_de_plata, 1))='') and p.cod=@Cod)  
 order by (case when c.tip='BK' or rtrim(left(p.mod_de_plata, 1))='' then 0 else 1 end), c.data desc, c.termen  
   
end  
  
if (@Pret is null or @Discount is null) and @TabelaPreturi=1  
begin  
   
 select @CategPret=sold_ca_beneficiar  
 from terti  
 where @TabelaPreturi=1 and @CategPret=0 and @Tert<>''   
 and subunitate=@Sb and tert=@Tert  
   
 set @CategPret=(case when isnull(@CategPret, 0)=0 then 1 else @CategPret end)  
  
 select @TipCategorie=0, @CategorieInValuta=0, @PretReferinta=0  
 select @TipCategorie=tip_categorie, @CategorieInValuta=in_valuta  
 from categpret  
 where categorie=@CategPret  
   
 select top 1 @PretReferinta=(case when @IauPretAmanunt=1 then pret_cu_amanuntul else pret_vanzare end)  
 from preturi  
 where		@TipCategorie=3 and cod_produs=@Cod and UM=1 and tip_pret='1' and @Data between data_inferioara and data_superioara  
 order by data_inferioara desc  
   
 select top 1 @PretLuatInValuta=(case when @Pret is not null then @PretLuatInValuta when @TipCategorie=3 then 0 else @CategorieInValuta end),   
  @Pret=(case when @Pret is not null then @Pret when @TipCategorie=3 then @PretReferinta when @IauPretAmanunt=1 then pret_cu_amanuntul else pret_vanzare end),   
  @Discount=(case when @Discount is null and @TipCategorie=3 then pret_vanzare else @Discount end),   
  @AnulareDiscount=(case when @Pret is null and tip_pret='9' then 1 else @AnulareDiscount end)   
 from preturi p  
 where cod_produs=@Cod and p.UM=@CategPret and tip_pret in ('1', '2', '9')   
 and @Data between data_inferioara and data_superioara and (tip_pret<>'2' or data_superioara<='12/31/2998')  
 order by (case when tip_pret='9' then 0 else 1 end),   
  /*pretul impus are prioritate; dintre un pret promo si unul de lista se va alege pretul mai mic*/  
  (case when @Pret is not null then @Pret when @TipCategorie=3 then @PretReferinta when @IauPretAmanunt=1 then pret_cu_amanuntul else pret_vanzare end),   
  tip_pret DESC, data_inferioara desc, data_superioara  
end  
  
if @Pret is null and @TabelaPreturi=0  
begin  
 select @Pret=(case when @IauPretAmanunt=1 then pret_cu_amanuntul else pret_vanzare end), @PretLuatInValuta=0  
 from nomencl  
 where cod=@Cod  
end  
  
if @Discount is null  
begin  
 select @Discount=(case when terti.disccount_acordat<>0 then terti.disccount_acordat when isnull(gterti.discount_acordat, 0)<>0 then gterti.discount_acordat else @Discount end)  
 from terti left join gterti on terti.grupa=gterti.grupa  
 where terti.subunitate=@Sb and terti.tert=@Tert  
end  
  
select @Discount=(case when @AnulareDiscount=1 then 0 else isnull(@Discount, 0) end), @Pret=isnull(@Pret, 0)  
  
if @PretLuatInValuta<>@DocumentInValuta  
begin  
 declare @Curs float, @valuta varchar(3)    
 select top 1 @Curs=curs, @valuta=nomencl.Valuta   
 from curs, nomencl  
 where nomencl.cod=@Cod and curs.valuta=nomencl.valuta and curs.data<=@Data  
 order by curs.data DESC  
 if (@valuta = 'RON' or isnull(@valuta,'')='') --and @curs=0  
  set @curs=1  
    
 set @Pret=round(convert(decimal(15, 5), (case when isnull(@Curs, 0)=0 then 0 when @PretLuatInValuta=1 then @Pret*@Curs else @Pret/@Curs end)), 5)  
end  