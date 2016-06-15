--***
create procedure wScriuCoduriVamale @sesiune varchar(50),@parXML xml
as 
declare @cod varchar(20), @denumire varchar(80), @um varchar(3), @um2 varchar(3), @coef_conv float, 
	@taxa_UE real, @taxa_AELS real, @taxa_GB real, @taxa_alte real, @comision_vamal real, @randament float, @tipcod int, @val2 float,
	@codnc8 varchar(20), @um_supl varchar(3), @update int, @o_cod varchar(20), @mesaj varchar(254)

select @cod=isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),''),
	@o_cod=isnull(@parXML.value('(/row/@o_cod)[1]','varchar(20)'),''),
	@denumire=isnull(@parXML.value('(/row/@denumire)[1]','varchar(80)'),''),
	@um=isnull(@parXML.value('(/row/@um)[1]','varchar(3)'),''),
	@um2=isnull(@parXML.value('(/row/@um2)[1]','varchar(3)'),''),
	@coef_conv=isnull(@parXML.value('(/row/@coefconv)[1]','decimal(12,4)'),0),
	@taxa_UE=isnull(@parXML.value('(/row/@taxaue)[1]','decimal(5,2)'),0),
	@taxa_AELS=isnull(@parXML.value('(/row/@taxaaels)[1]','decimal(5,2)'),0),
	@taxa_GB=isnull(@parXML.value('(/row/@taxagb)[1]','decimal(5,2)'),0),
	@taxa_alte=isnull(@parXML.value('(/row/@taxaalte)[1]','decimal(5,2)'),0),
	@comision_vamal=isnull(@parXML.value('(/row/@comvamal)[1]','decimal(5,2)'),0),
	@randament=isnull(@parXML.value('(/row/@randament)[1]','decimal(5,2)'),0),
	@tipcod=isnull(@parXML.value('(/row/@tipcod)[1]','int'),0),
	@val2=isnull(@parXML.value('(/row/@val2)[1]','float'),0),
	@codnc8=isnull(@parXML.value('(/row/@codnc8)[1]','varchar(20)'),''),
	@um_supl=isnull(@parXML.value('(/row/@umsupl)[1]','varchar(3)'),''),
	@update=isnull(@parXML.value('(/row/@update)[1]','int'),0)

begin try
--	validari functie de tipul de cod selectat
	if @tipcod<>1 and @codnc8<>''
		raiserror ('Cod NC8 se completeaza doar pt. tip cod=1 (cod nomenclator combinat)',11,1)
	if @tipcod<>1 and @um_supl<>''
		raiserror ('UM suplimentara se completeaza doar pt. tip cod=1 (cod nomenclator combinat)!',11,1)
	if @coef_conv<>0 and (@tipcod=1 or @um2='')
		raiserror ('Coeficient de conversie se completeaza doar pt. tip cod=2 (cod vamal) si daca UM2 este completat!',11,1)
	if @tipcod<>0 and (@um<>'' or @um2<>'' or @taxa_ue<>0 or @taxa_aels<>0 or @taxa_gb<>0 or @taxa_alte<>0 or @comision_vamal<>0 or @Randament<>0)
		raiserror ('Elementele "UM, UM2, Taxa UE, Taxa AELS, Taxa GB, Taxa alte tari, Comision vamal, Randament" se completeaza doar pt. tip cod=0 (coduri vamale)!',11,1)

	if @update=1 
	begin  
		if exists (select 1 from nomencl where substring(Tip_echipament,2,20)=@o_cod) and @cod<>@o_cod
			raiserror ('Acest cod vamal a fost atasat unui cod de nomenclator, nu i se poate schimba codificarea',11,1)
		else	
			update codvama set Cod=@cod, Denumire=@denumire, UM=@um, UM2=@um2, Coef_conv=@coef_conv, Taxa_UE=@taxa_UE, Taxa_AELS=@taxa_AELS, Taxa_GB=@taxa_GB, Taxa_alte_tari=@taxa_alte,
			Comision_vamal=@comision_vamal, Randament=@randament, Alfa1=@codnc8, Alfa2=@um_supl, Val1=@tipcod, Val2=@val2
			where Cod=@o_cod
	end  
	else   
	begin 
		if exists (select 1 from codvama where Cod=@cod)
			raiserror ('Acest cod vamal se gaseste deja in catalogul de coduri vamale!',11,1)
		else			 
			insert into codvama (Cod, Denumire, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament, Alfa1, Alfa2, Val1, Val2)  
			values (upper(@cod), upper(@denumire), @um, @um2, @coef_conv, @taxa_UE, @taxa_AELS, @taxa_GB, @taxa_alte, @comision_vamal, @randament, @codnc8, @um_supl, @tipcod, @val2)  
	end  
end try
begin catch
	set @mesaj = '(wScriuCoduriVamale:) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
  /*
  sp_help valuta
  */ 
