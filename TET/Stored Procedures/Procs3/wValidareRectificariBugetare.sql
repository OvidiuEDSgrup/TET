create proc [dbo].[wValidareRectificariBugetare] (@parXML xml)
as begin
Declare @update bit,@grup bit, @eroare xml,@indbug varchar(20),@suma float,@valuta varchar(3),
        @curs float,@suma_valuta float,@explicatii varchar(50),@lm char(9), 
        @nr_pozitie int,@loc_munca varchar(9),@comanda varchar(40),@tert varchar(13),@jurnal varchar(3),
        @data_operarii datetime,@ora_operarii varchar(6),@trimestru varchar(5),@o_nr_pozitie float,@o_data datetime,
        @mesajeroare varchar(100),@data datetime
Select
	 @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
	 @indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
	 @lm = isnull(@parXML.value('(/row/row/@lm)[1]','char(9)'),''),
	 @grup = isnull(@parXML.value('(/row/@grup)[1]','bit'),0),
	 @indbug =@parXML.value('(/row/@indbug)[1]','varchar(20)'),
     @trimestru = isnull(@parXML.value('(/row/row/@trimestru)[1]','varchar(5)'),0),
     @suma = isnull(@parXML.value('(/row/row/@suma)[1]','float'),0),
     @valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','varchar(3)'),''),
     @curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
     @data = @parXML.value('(/row/row/@data)[1]','datetime'),
     @o_data = @parXML.value('(/row/row/@o_data)[1]','datetime'),
     @explicatii = isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(50)'),''),
     @valuta=case when @valuta='nul' then '' else @valuta end 
	
	set @trimestru=(case when @trimestru='I' then '1'
                         when @trimestru='II' then '2'
                         when @trimestru='III' then '3'
                         when @trimestru='IV' then '4' end)
		
	if @grup=1		
	begin
		set @mesajeroare='Nu se pot adauga rectificari unui indicator care are grup!'
		raiserror(@mesajeroare,11,1)		
		return -1
	end
		
	if @suma<0
	begin
	    declare @suma_angajata float,@plan_alocat float	,@data_ultim_angbug datetime
		set @data_ultim_angbug=isnull((select max(data) from angbug where indicator=@indbug and Loc_de_munca=@lm and year(data)=year(@data)),'2099-01-01')
		set @plan_alocat=isnull(convert(decimal(12,3),      
                        (select sum(p.suma) from pozncon p where substring(p.comanda,21,20)=@indbug and p.tip='AO'  
                                                             and substring(p.numar,1,7)in ('BA_TRIM','RB_TRIM')
                                                             and (p.Loc_munca=@lm or isnull(@lm,'')='')
                                                             and (datepart(quarter,data)<=datepart(quarter,@data_ultim_angbug)or @trimestru>datepart(quarter,@data_ultim_angbug))
                                                             and year(p.data)=year(@data))),0)  		
		set @suma_angajata=isnull(convert(decimal(12,3), 
		                         (select sum(suma)from angbug where indicator=@indbug 
		                                                        and (Loc_de_munca=@lm or isnull(@lm,'')='')
		                                                        and year(data)=year(@data))),0)

		--select @plan_alocat,@suma,@suma_angajata
	  if @plan_alocat+@suma<@suma_angajata
	    begin 
		set @mesajeroare='Bugetul alocat rezultat in urma aceste rectificari nu acopera angajamentele bugetare deja realizate!'
		raiserror(@mesajeroare,11,1)		
		return -1
		end
	end
	
	if isnumeric(@suma)<>1 
	begin
		set @mesajeroare='Suma nu a fost completata corect!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
	if @suma=0 
	begin
		set @mesajeroare='Suma nu a fost completata!'
		raiserror(@mesajeroare,11,1)	
		return -1
	end
	
	
	if @valuta <>'' and @curs=0		
	begin
		set @mesajeroare='Cursul valutar nu a fost completat!'
		raiserror(@mesajeroare,11,1)	
		return -1
	end

	if @valuta='' and @curs<>0		
	begin
		set @mesajeroare='Valuta nu a fost completata!'		
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
	return 0
end
