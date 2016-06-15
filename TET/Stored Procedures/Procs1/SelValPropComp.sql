--***
create procedure SelValPropComp @CodProprietate char(20), @NrColoane int
as
declare @prop varchar(20), @nrord int, @propp varchar(20), @nrordp int, 
	@contor int, @nrordstr varchar(3), @tabv varchar(100), @tabvp varchar(100),
	@select varchar(8000), @from varchar(8000), @where varchar(8000), @order varchar(8000), @sir varchar(8000)

declare tmppropc cursor for
	select c.proprietate_componenta, c.numar_de_ordine, p.proprietate_parinte, isnull(c1.numar_de_ordine, -1) as nrordp
	from compproprietati c
	inner join catproprietati p on p.cod_proprietate=c.proprietate_componenta
	left outer join compproprietati c1 on c1.cod_proprietate=c.cod_proprietate and c1.proprietate_componenta=p.proprietate_parinte
	where c.cod_proprietate=@CodProprietate
	order by c.numar_de_ordine

open tmppropc
fetch next from tmppropc into @prop, @nrord, @propp, @nrordp
set @contor=0
set @select='SELECT '
set @from='FROM '
set @where='WHERE '
set @order='ORDER BY '
while @@fetch_status=0
begin
	set @nrordstr = ltrim(str(@nrord))
	set @tabv='v' + @nrordstr
	--set @select = @select + '''' + rtrim(@prop) + ''' as proprietate' + @nrordstr + ', '
	set @select = @select + @tabv + '.valoare as valoare' + @nrordstr + ', '
	set @from = @from + 'valproprietati ' + @tabv + ', '
	set @where = @where + @tabv + '.cod_proprietate=''' + rtrim(@prop) + ''' and '
	if @propp<>'' and @nrordp>0
	begin
		set @tabvp = 'v' + ltrim(str(@nrordp))
		set @where = @where + @tabv + '.valoare_proprietate_parinte=' + @tabvp + '.valoare and '
	end
	set @order = @order + 'valoare' + @nrordstr + ', '
	set @contor = @contor + 1
	fetch next from tmppropc into @prop, @nrord, @propp, @nrordp
end
close tmppropc
deallocate tmppropc

while @contor < @NrColoane
begin
	set @contor = @contor + 1
	set @select = @select + ''''' as nevaloare' + ltrim(str(@contor)) + ', '
end

set @select = left(@select, len(@select)-1)
set @from = left(@from, len(@from)-1)
set @where = left(@where, len(@where)-4)
set @order = left(@order, len(@order)-1)
set @sir = @select + CHAR(13) + CHAR(10) + @from + CHAR(13) + CHAR(10) + @where + CHAR(13) + CHAR(10) + @order + CHAR(13) + CHAR(10)

exec (@sir)
