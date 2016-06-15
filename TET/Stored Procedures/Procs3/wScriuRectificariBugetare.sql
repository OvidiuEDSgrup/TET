--***
create procedure [dbo].[wScriuRectificariBugetare] @sesiune varchar(50), @parXML xml  
as
declare	@mesajeroare varchar(100),@utilizator char(10), @userASiS varchar(20),@sub char(9)
	
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
if @utilizator is null
	return -1

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

DECLARE @indbug varchar(20),@eroare xml, @tip varchar(2),@numar varchar(13),@dataR datetime,@cont_debitor varchar(13),
        @cont_creditor varchar(13),@suma float,@valuta varchar(3),@lm char(9), 
        @curs float,@suma_valuta float,@explicatii varchar(50),
        @nr_pozitie int,@loc_munca varchar(9),@comanda varchar(40),@tert varchar(13),@jurnal varchar(3),
        @data_operarii datetime,@ora_operarii varchar(6),@trimestru varchar(5),@o_nr_pozitie float,@o_data datetime,
        @update bit, @anplan int

begin try
select	@anplan = isnull(@parXML.value('(/row/@anplan)[1]','int'),0),
		@lm = isnull(@parXML.value('(/row/row/@lm)[1]','char(9)'),''),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
		@trimestru = isnull(@parXML.value('(/row/row/@trimestru)[1]','varchar(5)'),0),
		@suma = isnull(@parXML.value('(/row/row/@suma)[1]','float'),0),
		@o_nr_pozitie = isnull(@parXML.value('(/row/row/@o_nr_pozitie)[1]','float'),0),
		@valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','varchar(3)'),''),
		@curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
		@o_data = isnull(@parXML.value('(/row/row/@o_data)[1]','datetime'),''),
		@dataR = @parXML.value('(/row/row/@data)[1]','datetime'),
		@explicatii = isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(50)'),''),
		@valuta=case when @valuta='nul' then '' else @valuta end 
  
if exists (select 1 from sys.objects where name='wScriuRectificariBugetareSP' and type='P')  
	exec wScriuRectificariBugetareSP @sesiune, @parXML
	 
	set @suma_valuta=(case when @curs<>0 and @valuta<>'' then @suma/@curs else 0 end)
	set @comanda=space(20)+@indbug
    set @trimestru=(case when @trimestru='I' then '1'
                         when @trimestru='II' then '2'
                         when @trimestru='III' then '3'
                         when @trimestru='IV' then '4' end)
    set @explicatii=case when isnull(@explicatii,'')='' then 'Rectificare buget trim. '+@trimestru else @explicatii end                     

	exec wValidareRectificariBugetare @parXML	
	
	if @update=1  
	--Modificare rectificare bugetara
	 update pozncon set suma=@suma,valuta=@valuta,curs=@curs,suma_valuta=@suma_valuta,explicatii=@explicatii,
					  utilizator=@utilizator,data_operarii=convert(datetime, convert(char(10), getdate(), 101), 101),
					  ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))                  
		 where substring(comanda,21,20) = @indbug and subunitate='1' and tip='AO' and nr_pozitie=@o_nr_pozitie 
	 
	else
	begin
	--Adaugare rectificare bugetara
	 exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitie output, ''
	 set @nr_pozitie=@nr_pozitie+1
	 exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitie, null 

	 declare @datatrim datetime
 	 set @datatrim=dateadd(day,-1,DATEADD(month, 3*@trimestru, '01/01/'+LTRIM(str(@anplan))))

	 insert into pozncon(subunitate,tip,numar,data,cont_debitor,cont_creditor,suma,valuta,
				 curs,suma_valuta,explicatii,utilizator,data_operarii,ora_operarii,nr_pozitie,loc_munca,comanda,tert,jurnal) 
				 values( '1','AO','RB_TRIM'+@trimestru,@datatrim,'8060','',@suma,@valuta,@curs,@suma_valuta,@explicatii,@utilizator,
						convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
						,@nr_pozitie,@lm,@comanda,CONVERT(char(10),@dataR,103),'')				
	end

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch

--select * from pozncon where comanda='                    54025001100102 '
--delete from pozncon where comanda='101.1.1.6'and nr_pozitie=195738
