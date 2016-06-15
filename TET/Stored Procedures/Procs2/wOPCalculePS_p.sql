--***
/* procedura pentru populare macheta tip 'operatii' - calcule salarii / declaratii */
Create procedure wOPCalculePS_p @sesiune varchar(50), @parXML xml 
as  

declare @codMeniu varchar(20), @tipDetaliere varchar(2), @data datetime, @Luna int, @An int, @datajos datetime, @datasus datetime, @nLunaInch int, @nAnulInch int, 
@NCTichete int, @NCZilieri int, @ImpozitPlD112 int, @ImpPLFaraSal int, @LmImpStatPl int, 
@ContCASSAgricol varchar(13),	--> Cont asigurari de sanatate retinute la achizitia de cereale 
@ContImpozitAgricol varchar(13),	--> Cont impozit retinut la achizitia de cereale 
@contImpozit char(30), @contFactura char(30), @contImpozitDividende char(30),	--> conturi pentru declaratia 205
@numedecl varchar(75), @prendecl varchar(75), @functiedecl varchar(75), 
@tipsocietate varchar(60), @reprlegal varchar(100), 
@CalculCONetFDP int, @RecalcCOGenDinLuniAnt int, @RecalculMedieZilnica int, @PrelVechime int, @PrelSpVech int, @PrelSpSpec int, @PrelRetineri int, 
@PrelAvans int, @PrelPersintr int, @PrelCorLm int, @PrelCONeefect int, @PrelPensiiFac int, @PrelParLunari int,
@marca varchar(6), @densalariat varchar(50), @data_inceput datetime, @tip_diagnostic varchar(2), @datastagiu datetime, @update int, 
@utilizator varchar(10), @Precizie int

exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

select @codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(20)'),'')
select @tipDetaliere=isnull(@parXML.value('(/row/@TipDetaliere)[1]','varchar(2)'),'')
if @tipDetaliere='ME' 
Begin
	select @marca=isnull(@parXML.value('(/row/row/@marca)[1]','varchar(6)'),'')
	select @data_inceput=isnull(@parXML.value('(/row/row/@datainceput)[1]','datetime'),'')
	select @tip_diagnostic=isnull(@parXML.value('(/row/row/@tipconcediu)[1]','varchar(2)'),'')
	select @densalariat=nume from personal where Marca=@marca
End
if @codMeniu='S' and @tipDetaliere in ('SM','SO')
Begin
	select @marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),'')
	select @update=isnull(@parXML.value('(/row/row/@update)[1]','int'),'')
	if @update=0
		select @datastagiu=dbo.eom(DateAdd(month,-1,Data_angajarii_in_unitate)) from personal where Marca=@marca
	else 
		select @datastagiu=isnull(@parXML.value('(/row/row/@data)[1]','datetime'),'')
End	
set @NCTichete=dbo.iauParL('PS','NC-TICHM')
-- parametrii pt. D112
set @ImpozitPlD112=dbo.iauParL('PS','D112IMZPL')
set @ImpPLFaraSal=dbo.iauParL('PS','D112IPLFS')
set @LmImpStatPl=dbo.iauParL('PS','D112PLLMS')
set @ContCASSAgricol=dbo.iauParA('PS','D112CASAA')
set @ContImpozitAgricol=dbo.iauParA('PS','D112CIMAA')
-- parametrii pt. D205
set @contImpozit=dbo.iauParA('PS','D205CTIMP')
set @contFactura=dbo.iauParA('PS','D205CTFAC')
set @contImpozitDividende=dbo.iauParA('PS','D205CTDIV')
-- parametrii pt. semnaturi declaratii
set @numedecl=dbo.iauParA('PS','NPERSAUT')
set @prendecl=dbo.iauParA('PS','PPERSAUT')
set @functiedecl=dbo.iauParA('PS','FPERSAUT')
set @tipsocietate=dbo.iauParA('PS','ITMTIPSOC')
set @reprlegal=dbo.iauParA('PS','ITMNUME')

set @Precizie=dbo.iauParN('PS','PRECIZIE')
set @CalculCONetFDP=dbo.iauParL('PS','CO-NETFDP')
set @RecalcCOGenDinLuniAnt=dbo.iauParL('PS','CO-RCIT78')
set @RecalculMedieZilnica=dbo.iauParL('PS','RMZCALCM')
set @PrelVechime=dbo.iauParL('PS','VECTOTSAL')
set @PrelSpVech=dbo.iauParL('PS','SPORVECHS')
set @PrelSpSpec=dbo.iauParL('PS','SPORSPES')
set @PrelRetineri=dbo.iauParL('PS','RETOPRETI')
set @PrelAvans=dbo.iauParL('PS','PRELAVEXC')
set @PrelPersintr=dbo.iauParL('PS','PRCFPSINT')
set @PrelPersintr=1
set @PrelCorLm=dbo.iauParL('PS','PRELCORLM')
set @PrelCONeefect=dbo.iauParL('PS','ZILECORAM')
set @PrelParLunari=1

set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
Select @luna=(case when @nLunaInch=12 then 1 else @nLunaInch+1 end),
	@An=(case when @nLunaInch=12 then @nAnulInch+1 else @nAnulInch end)
if @codMeniu in ('D2')
	select @an=isnull(@parXML.value('(/row/@an)[1]','int'),''), 
		@luna=isnull(@parXML.value('(/row/@luna)[1]','int'),'')

if @nLunaInch not between 1 and 12 or @nAnulInch<=1901
	Select @luna=month(getdate()), @An=year(getdate())

set @datajos=convert(datetime,str(@luna,2)+'/01/'+str(@an,4))
set @datasus=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @data=@datasus
set @PrelPensiiFac=(case when @nLunaInch=11 then 1 else 0 end)
if exists (select * from sysobjects where name ='SalariiZilieri') 
	if exists (select Marca from SalariiZilieri where Data between @datajos and @datasus)
		set @NCZilieri=1

select convert(char(10),@data,101) as data
	,(case when @codMeniu='S' and @tipDetaliere='SM' then month(@datastagiu) when @codMeniu='RV' then month(getdate()) else @Luna end) as luna
	,(case when @codMeniu='S' and @tipDetaliere='SM' then year(@datastagiu) when @codMeniu='RV' then year(getdate()) else @An end) as an
	,@datajos as datajos, @datasus as datasus
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelVechime end) as prelvech
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelSpVech end) as prelspvech
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelSpSpec end) as prelspspec
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelRetineri end) as prelretineri
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelAvans end) as prelavans
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelPersintr end) as prelpersintr
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelCorLm end) as prelcorlm
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelCONeefect end) as prelconeef
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelPensiiFac end) as prelpensiif
	,(case when @codMeniu in ('IS','ILPS','O_IS') then @PrelParLunari end) as prelparlun
	,(case when @codMeniu='OD' then @CalculCONetFDP end) as calcconetfdp
	,(case when @codMeniu='OD' then @RecalcCOGenDinLuniAnt end) as recalccolant
	,(case when @codMeniu='ME' then 1 /*@RecalculMedieZilnica*/ end) as recalculmedzi,
	(case when @codMeniu='PA' and 1=0 then 1 end) as stergere
	,(case when @codMeniu='PA' then 1 end) as generare
	,(case when @codMeniu='SL' and @tipDetaliere='ME' then rtrim(@marca) end) as marca
	,(case when @codMeniu='SL' and @tipDetaliere='ME' then rtrim(@densalariat) end) as densalariat
	,(case when @codMeniu='SL' and @tipDetaliere='ME' then convert(char(10),@data_inceput,101) end) as datainceput
	,(case when @codMeniu='SL' and @tipDetaliere='ME' then @tip_diagnostic end) as tipconcediu
--	calcul salarii
	,(case when @codMeniu in ('CS','CSAL') then 1 end) as calculco
	,(case when @codMeniu in ('CS','CSAL') then 1 end) as calculcm 
--	(case when @codMeniu in ('CS','CSAL') then 1 end) as calculacord
	,(case when @codMeniu in ('CS','CSAL') then 1 end) as calcullich
	,(case when @codMeniu in ('CS','CSAL') then 1 end) as cbrutnet
	,(case when @codMeniu in ('CS','CSAL') then @precizie end) as precizie
--	generare note contabile salarii
	,(case when @codMeniu='NS' then 1 end) as stergncsal
	,(case when @codMeniu='NS' and @NCTichete=1 then 1 end) as stergnctich
	,(case when @codMeniu='NS' and @NCZilieri=1 then 1 end) as stergnczilieri
	,(case when @codMeniu='NS' or @codMeniu in ('CS','CSAL') and (dbo.f_areLMFiltru(@utilizator)=0 or 1=1) then 1 end) as genncsal
	,(case when @codMeniu='NS' and @NCTichete=1 then 1 end) as gennctich
	,(case when @codMeniu='NS' and @NCZilieri=1 then 1 end) as gennczilieri
--	declaratia 112
	,(case when @codMeniu='DU' and @ImpozitPlD112=1 then 1 end) as impozitpl
	,(case when @codMeniu='DU' and @ImpPLFaraSal=1 then 1 end) as impplfarasal
	,(case when @codMeniu='DU' and @LmImpStatPl=1 then 1 end) as lmimpstatpl
	,(case when @codMeniu='DU' then rtrim(@ContCASSAgricol) end) as contcass
	,(case when @codMeniu='DU' then rtrim(@ContImpozitAgricol) end) as contimpozitagricol
--	declaratia 205
	,(case when @codMeniu='D2' then rtrim(@contImpozit) end) as contimpozit
	,(case when @codMeniu='D2' then rtrim(@contFactura) end) as contfactura
	,(case when @codMeniu='D2' then rtrim(@contImpozitDividende) end) as contimpozitdiv
--	declaratii
	,(case when @codMeniu in ('DU','D2') then rtrim(@numedecl) end) as numedecl
	,(case when @codMeniu in ('DU','D2') then rtrim(@prendecl) end) as prendecl
	,(case when @codMeniu in ('DU','D2') then rtrim(@functiedecl) end) as functiedecl
	,(case when @codMeniu='RV' then rtrim(@tipsocietate) end) as tipsoc
	,(case when @codMeniu='RV' then rtrim(@reprlegal) end) as reprlegal
	,(case when @codMeniu='BS' then '1.Nu pot fi actualizate date lunare'
		+CHAR(13)+REPLICATE('-',57)+CHAR(13)+'2.Pot fi efectuate calcule'
		+CHAR(13)+REPLICATE('-',57)+CHAR(13)+'3.Pot fi consultate datele'
		+CHAR(13)+REPLICATE('-',57)+CHAR(13)+'4.Pot fi editate situatii' end) as descriere
for xml raw
