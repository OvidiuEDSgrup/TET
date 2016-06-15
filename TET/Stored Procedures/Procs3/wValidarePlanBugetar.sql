create proc [dbo].[wValidarePlanBugetar] (@parXML xml)
as begin
Declare @update bit,@grup bit,@indbug varchar(20),@valuta varchar(3),@data datetime,
        @curs float,@suma_valuta float,@explicatii varchar(50),@mesajeroare varchar(500),
        @nr_pozitie int,@loc_munca varchar(9),@comanda varchar(40),@tert varchar(13),@jurnal varchar(3),
        @data_operarii datetime,@ora_operarii varchar(6),@trimestru varchar(5),@o_nr_pozitie float,@o_data datetime,
        @suma1 float,@suma2 float,@suma3 float,@suma4 float,@o_suma1 float,@o_suma2 float,@o_suma3 float,@o_suma4 float
	
select	
	 @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
	 @grup = isnull(@parXML.value('(/row/@grup)[1]','bit'),0),
	 @indbug =isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
     @trimestru = isnull(@parXML.value('(/row/row/@trimestru)[1]','varchar(5)'),0),
     @suma1 = isnull(@parXML.value('(/row/row/@suma1)[1]','float'),0),
     @suma2 = isnull(@parXML.value('(/row/row/@suma2)[1]','float'),0),
     @suma3 = isnull(@parXML.value('(/row/row/@suma3)[1]','float'),0),
     @suma4 = isnull(@parXML.value('(/row/row/@suma4)[1]','float'),0),
     @o_suma1 = isnull(@parXML.value('(/row/row/@o_suma1)[1]','float'),0),
     @o_suma2 = isnull(@parXML.value('(/row/row/@o_suma2)[1]','float'),0),
     @o_suma3 = isnull(@parXML.value('(/row/row/@o_suma3)[1]','float'),0),
     @o_suma4 = isnull(@parXML.value('(/row/row/@o_suma4)[1]','float'),0),
     @valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','varchar(3)'),''),
     @curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
     @o_data = @parXML.value('(/row/row/@o_data)[1]','datetime'),
     @explicatii = isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(50)'),''),
     @data = isnull(@parXML.value('(/row/row/@data)[1]','datetime'),'01-01-1901'),
     @valuta=case when @valuta='nul' then '' else @valuta end 	   

	if @grup=1		
	begin
		set @mesajeroare='Nu se pot adauga plan bugetar unui indicator care are grup!'
		raiserror(@mesajeroare,11,1)		
		return -1
	end
	
	if @valuta<>'' and @curs=0
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
		
	/*if (@suma1<>@o_suma1 or @suma2<>@o_suma2 or @suma3<>@o_suma3 or @suma4<>@o_suma4 ) and @update='1' 
		and isnull(convert(decimal(12,3),(select sum(suma)from angbug where indicator=@indbug 
		                                                                 --and datepart(quarter,data)<=convert(int,@trimestru)
		                                                                 and year(data)=year(@data))),0)<>0
		begin 
			set @mesajeroare='Pe planul alocat acestui indicator bugetar s-au factut deja angajamente bugetare, prin urmare suma lui nu mai poate fi modificata decat prin rectificare!'
			raiserror(@mesajeroare,11,1)		
			return -1
		end*/
	return 0
end
