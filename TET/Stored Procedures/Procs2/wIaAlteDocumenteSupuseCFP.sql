create procedure  [dbo].[wIaAlteDocumenteSupuseCFP] @sesiune varchar(50), @parXML XML    
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaAlteDocumenteSupuseCFPSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wIaAlteDocumenteSupuseCFPSP @sesiune, @parXML output
	return @returnValue
end
begin try    
	Declare	@cSub char(9), @utilizator varchar(20),@mesajeroare varchar(500),@indbug varchar(20),@tip_CFP varchar(1),@numar varchar(80),
		@f_indbug varchar(100),@datasus datetime,@datajos datetime,@data datetime,@numar_pozitie int,@f_numar varchar(20)
 --citire date din xml
	select 
		@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),''),
		@indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
		@tip_CFP=isnull(@parXML.value('(/row/@tip_CFP)[1]','varchar(1)'),''),
		@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(8)'),''),
		@numar_pozitie=isnull(@parXML.value('(/row/@numar_pozitie)[1]','int'),0),
		@f_indbug = isnull(@parXML.value('(/row/@f_indbug)[1]','varchar(100)'),''),
		@f_numar = isnull(@parXML.value('(/row/@f_numar)[1]','varchar(20)'),''),
		@f_indbug = replace(@f_indbug,'.','')  
   
	exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output    
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	    
	select distinct top 100 rtrim(a.Tip) as tip_CFP,convert(varchar(10),a.Data,101) as data,RTRIM(a.Indicator)as indbug,RTRIM(a.Numar) as numar,
		a.Stare as stare,rtrim(a.Loc_de_munca) as compartiment,RTRIM(a.Beneficiar)as beneficiar,RTRIM(a.Valuta)as valuta,convert (decimal(17,3),a.suma) as suma,
		convert (decimal(17,3),a.Curs) as curs,convert (decimal(17,3),a.Suma_valuta) as suma_valuta,rtrim(a.Explicatii) as scop,RTRIM(a.observatii)as observatii,
		r.numar_pozitie,RTRIM(r.Numar_CFP)as numar_CFP,CONVERT(char(10),r.data_cfp,101)as data_CFP,rtrim(lc.Denumire) as denCompartiment,RTRIM(lb.Denumire)as denBeneficiar
	FROM  altedocCFP a
		left join registrucfp r on a.indicator=r.Indicator and a.Tip=r.Tip and a.Numar=r.Numar and a.Data=r.Data
		left outer join lm lc on lc.Cod=a.Loc_de_munca
		left outer join lm lb on lb.Cod=a.Beneficiar 
	where (a.Tip=@tip_CFP or isnull(@tip_CFP,'')='')
		and (a.Data=@data or ISNULL(@data,'')='')
		and (a.Indicator=@indbug or ISNULL(@indbug,'')='')
		and (a.Numar=@numar or ISNULL(@numar,'')='')
		and a.Data between @datajos and @datasus
		and (a.Indicator like @f_indbug+'%' or ISNULL(@f_indbug,'')='')
		and (a.Numar like @f_numar+'%' or ISNULL(@f_numar,'')='')
	for xml raw  
	  
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
