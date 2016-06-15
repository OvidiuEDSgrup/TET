create procedure  [dbo].[wScriuPlanBugetar] @sesiune varchar(50), @parXML xml  
as
begin try
	declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9)
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1

	DECLARE @indbug varchar(20),@eroare xml ,@suma float, @lm char(9), @suma1 float, @suma2 float, @suma3 float, @suma4 float,
		@valuta varchar(3), @curs float,@suma_valuta float,@explicatii varchar(50),@data datetime,
        @nr_pozitie int,@loc_munca varchar(9),@comanda varchar(40),@tert varchar(13),@jurnal varchar(3),
        @data_operarii datetime,@ora_operarii varchar(6),@trimestru varchar(5),@o_nr_pozitie float,@o_data datetime,
        @update bit, @anplan int,@anchar varchar(20)

	select  
		@anchar= isnull(@parXML.value('(/row/@anplan)[1]','int'),0),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
		@trimestru = isnull(@parXML.value('(/row/row/@trimestru)[1]','varchar(5)'),0),
		@suma = isnull(@parXML.value('(/row/row/@suma)[1]','float'),0),
		@lm = isnull(@parXML.value('(/row/row/@lm)[1]','char(9)'),''),
		@suma1 = isnull(@parXML.value('(/row/row/@suma1)[1]','float'),0),
		@suma2 = isnull(@parXML.value('(/row/row/@suma2)[1]','float'),0),
		@suma3 = isnull(@parXML.value('(/row/row/@suma3)[1]','float'),0),
		@suma4 = isnull(@parXML.value('(/row/row/@suma4)[1]','float'),0),
		@o_nr_pozitie = isnull(@parXML.value('(/row/row/@o_nr_pozitie)[1]','float'),0),
		@valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','varchar(3)'),''),
		@curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
		@o_data = isnull(@parXML.value('(/row/row/@o_data)[1]','datetime'),''),
		@data = isnull(@parXML.value('(/row/row/@data)[1]','datetime'),''),
		@explicatii = isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(50)'),''),
		@valuta=case when @valuta='nul' then '' else @valuta end 
 
	if isnumeric(@anchar)=1
		set @anplan=convert(int,@anchar)
	else 
		set @anplan=year(getdate())

	if exists (select 1 from sys.objects where name='wScriuPlanBugetarSP' and type='P')  
		exec wScriuPlanBugetarSP @sesiune, @parXML
	 
	-- else 
	select convert(varchar,@suma)
    set @suma_valuta=(case when @curs<>0 and @valuta<>'' then @suma/@curs else 0 end)
	set @comanda=space(20)+@indbug    
    set @trimestru=(case when @trimestru='I' then '1'
                         when @trimestru='II' then '2'
                         when @trimestru='III' then '3'
                         when @trimestru='IV' then '4' end)    
  
	exec  wValidarePlanBugetar @parXML
	if exists (select 1 from pozncon p where p.tip='AO' and left(p.numar,2)='BA' and year(p.data)=@anplan 
		and substring(p.comanda,21,20)=@indbug and p.loc_munca =@lm)
		begin
			if @update=0 
				begin
				set @mesajeroare = 'Pe locul de munca indicat exista plan bugetar pentru anul '+ltrim(STR(@anplan))+'!'
				raiserror(@mesajeroare, 11, 1)
				end
			else
				delete pozncon from pozncon p where p.tip='AO' and left(p.numar,2)='BA' and year(p.data)=@anplan 
				and substring(p.comanda,21,20)=@indbug and p.loc_munca =@lm
		end

--Adaugare plan bugetar 
	declare @var int
	set @var=1
	while @var<5
		begin	 
			declare @datatrim datetime, @sumatrim float
			set @datatrim=dateadd(day,-1,DATEADD(month, 3*@var, '01/01/'+LTRIM(str(@anplan))))
			set @sumatrim=(case @var when 1 then @suma1 when 2 then @suma2 when 3 then @suma3 else @suma4 end)
			set @explicatii='Buget aprobat trim. '+LTRIM(str(@var))
			if @sumatrim<>0
				begin
					exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitie output, ''
					set @nr_pozitie=@nr_pozitie+1
					exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitie, null 
		 
					 insert into pozncon(subunitate,tip,numar,data,cont_debitor,cont_creditor,suma,valuta,
						curs,suma_valuta,explicatii,utilizator,data_operarii,ora_operarii,nr_pozitie,loc_munca,comanda,tert,jurnal) 
					 values( '1','AO','BA_TRIM'+LTRIM(str(@var)),@datatrim,'8060','',@sumatrim,@valuta,@curs,@suma_valuta,@explicatii,@utilizator,
						convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
						,@nr_pozitie,@lm,@comanda,'','')				
				end
			set @var=@var+1
		end	
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
