
create procedure wOPValidareTerti_p @sesiune varchar(50), @parXML xml
as

declare @v_terti table (tert varchar(13),CUI varchar(16),valid bit,ID int identity)

insert into @v_terti(tert,CUI)
select rtrim(t.Tert),rtrim(t.Cod_fiscal)
from terti t
where Tert_extern=0

update t
set CUI=ltrim(rtrim(replace(CUI,'RO','')))
from @v_terti t

update @v_terti 
set valid=0
where CUI like '%[a-zA-Z]%'

update @v_terti 
set valid=0
where len(CUI) > 10 or len(CUI) < 1

declare
	@curent int, @max int, @CUI varchar(16), @valid bit, @key varchar(9), @control int, @lungime int, @init int, @sum int, @mod int

select
	@curent = (select min(ID) FROM @v_terti),
	@max = (select max(ID) FROM @v_terti),
	@key = '235712357'

while (@curent <= @max)
begin
	set @CUI = (select CUI from @v_terti where ID=@curent)
	set @valid = (select valid from @v_terti where ID=@curent)
	if @valid is null
	begin
		select
			@control = convert(int,right(@CUI,1)),
			@lungime = len(@CUI)-1,
			@CUI = reverse(left(@CUI,len(@CUI)-1)),
			@init = 1,
			@sum = 0
		while (@init <= @lungime)
		begin
			set @sum = @sum + convert(int,substring(@CUI,@init,1)) * convert(int,substring(@key,@init,1))
			set @init = @init + 1
		end
		set @mod = ((@sum * 10) % 11)
		if @mod = 10
			set @mod = 0
		if @control = @mod
			update @v_terti set valid=1 where ID=@curent
		else
			update @v_terti set valid=0 where ID=@curent
	end	
	set @curent = @curent + 1
end

select (
	select rtrim(v.tert) as tert, rtrim(t.Denumire) as denumire, rtrim(t.cod_fiscal) as cod_fiscal
	from @v_terti v
		inner join terti t on v.tert=t.tert
	where v.valid <> 1
	for xml raw, type
) for xml path('DateGrid'),root('Mesaje')
