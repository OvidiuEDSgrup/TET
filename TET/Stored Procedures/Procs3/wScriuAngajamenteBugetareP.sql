create procedure  [dbo].[wScriuAngajamenteBugetareP] @sesiune varchar(50), @parXML xml  
as
declare	@mesajeroare varchar(300),@utilizator char(10), @sub char(9),@tip char(2)
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
if @utilizator is null
	return -1
	
declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE @indbug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),@o_indbug varchar (20), 
	        @data_operarii datetime,@ora_operarii varchar(6),@o_data datetime
	Declare @update bit,@numar varchar(8),@data datetime,@compartiment varchar(9),@beneficiar varchar(20),@suma float,
	        @valuta varchar(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float
        
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @indbug= isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
         @numar= isnull(@parXML.value('(/row/@numar)[1]','varchar(8)'),''),
         @data= @parXML.value('(/row/@data)[1]','datetime'),
         @compartiment= isnull(@parXML.value('(/row/@compartiment)[1]','varchar(9)'),''),
         @beneficiar= isnull(@parXML.value('(/row/@beneficiar)[1]','varchar(20)'),''),
         @suma= isnull(@parXML.value('(/row/@suma)[1]','float'),0),
         @valuta= isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),''),
         @curs=isnull( @parXML.value('(/row/@curs)[1]','float'),0),
         @explicatii=isnull( @parXML.value('(/row/@explicatii)[1]','varchar(200)'),''),
         @observatii= isnull(@parXML.value('(/row/@observatii)[1]','varchar(200)'),''),
         @o_indbug= isnull(@parXML.value('(/row/@o_indbug)[1]','varchar(20)'),''),
         @o_data= @parXML.value('(/row/@o_data)[1]','datetime')
         	 
		
	if exists (select 1 from sys.objects where name='wScriuAngajamenteBugetarePSP' and type='P')  
	exec wScriuAngajamenteBugetarePSP @sesiune, @parXML
else 
set @suma_valuta=(case when @curs<>0 and @valuta<>'' then @suma/@curs else 0 end) 
begin 
   set @eroare = dbo.wfValidareAngajamentBugetar(@parXML)
	if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
	begin
	set @mesajeroare=@eroare.value('(error/@msgeroare)[1]','varchar(200)')
		raiserror(@mesajeroare, 11, 1)
		end
	else
begin	
if @update=1  
begin
select numar,@numar,indicator,@o_indbug	,data,@o_data from angbug
 update angbug set indicator=@indbug,loc_de_munca=@compartiment,beneficiar=@beneficiar,
        suma=@suma,valuta=@valuta,curs=@curs,suma_valuta=@suma_valuta,explicatii=@explicatii,observatii=@observatii,
        utilizator=@utilizator,data_operarii=convert(datetime, convert(char(10), getdate(), 101), 101),
        ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) ,data_angajament='1901-01-01 00:00:00.000'
     where numar = @numar and indicator=@o_indbug and data=@o_data
end
else
 
 insert into angbug(indicator,numar,data,stare,loc_de_munca,beneficiar,suma,valuta,curs,suma_valuta,explicatii,
             observatii,utilizator,data_operarii,ora_operarii,data_angajament) 
             select @indbug,@numar,@data,'0',@compartiment,@beneficiar,@suma,@valuta,@curs,@suma_valuta,@explicatii,
             @observatii,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),
             RTrim(replace(convert(char(8), getdate(), 108), ':', '')) ,'1901-01-01 00:00:00.000'				
end
Select @mesajeroare as mesajeroare for xml raw  

end   

--select * from angbug
--delete from indbug where indbug=''
