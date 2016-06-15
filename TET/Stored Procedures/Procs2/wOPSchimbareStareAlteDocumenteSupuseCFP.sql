create procedure [dbo].[wOPSchimbareStareAlteDocumenteSupuseCFP] @sesiune varchar(50), @parXML xml  
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPSchimbareStareAlteDocumenteSupuseCFPSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPSchimbareStareAlteDocumenteSupuseCFPSP @sesiune, @parXML output
	return @returnValue
end
DECLARE @Sub char(9), @utilizator varchar(10),@mesajeroare varchar(200),@indbug varchar(20),@tip_CFP varchar(1),@numar varchar(8),
	@data datetime,@data_CFP datetime

begin try	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1

	select 
		@data = isnull(@parXML.value('(/parametri/@data)[1]','datetime'),''),
		@data_CFP = isnull(@parXML.value('(/parametri/@data_CFP)[1]','datetime'),''),
		@indbug = isnull(@parXML.value('(/parametri/@indbug)[1]','varchar(20)'),''),
		@tip_CFP=isnull(@parXML.value('(/parametri/@tip_CFP)[1]','varchar(1)'),''),
		@numar=isnull(@parXML.value('(/parametri/@numar)[1]','varchar(8)'),'')
  
    if exists(select 1 from registrucfp where Numar=@numar and data=@data and tip=@tip_CFP)
		raiserror('Acest document are deja alocata viza cfp!!',11,1)	
     
	declare @nr_cfp float,@nr_pozitie int
	exec luare_date_par 'GE', 'ULTNROPB', 0, @nr_cfp output, ''--identificam ultimul numar de cfp utilizat
	set @nr_cfp=@nr_cfp+1
	 
    set @nr_pozitie=isnull((select top 1 numar_pozitie from registrucfp 
	where indicator=@indbug and numar=@numar and data=@data and tip=@tip_CFP
	order by numar_pozitie desc),0)+1	--identificam numarul pozitiei
    
    --insert in registru noul numar cfp
	insert into registrucfp (tip,indicator,numar,data,numar_pozitie,numar_cfp,data_cfp,observatii,utilizator,data_operarii,ora_operarii)
		select @tip_CFP,@indbug,@numar,convert(datetime, convert(char(10), @data, 101), 101),@nr_pozitie,@nr_cfp,convert(datetime, convert(char(10), @data_CFP, 101), 101),
			observatii,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		from altedocCFP 
		where Numar=@numar and data=@data and tip=@tip_CFP and indicator=@indbug   
	
	exec setare_par 'GE', 'ULTNROPB', null, null, @nr_cfp, null --setare ultimul nr cfp utilizat
	
	--schimbam starea din operat->vizat in tabela de alte documente cfps
	update altedocCFP set Stare=2 where Numar=@numar and data=@data and tip=@tip_CFP and indicator=@indbug         

end try	
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
