--***
create function wfAdunScad (@tip varchar(1),@s1 varchar(1000),@s2 varchar(1000))
returns varchar(1000)
as
begin
	/*declare @tip varchar(1),@s1 varchar(1000),@s2 varchar(1000)
	set @tip='C'
	set @s1='TEST'
	set @s2='CHEIE'*/
	declare @i int,@minsir int,@c1 varchar(1),@c2 varchar(1),@rez varchar(1),@n1 int,@n2 int,@n int
	declare @raspuns varchar(1000)
	set @raspuns=''
	if len(@s1)<len(@s2)
		set @minsir=len(@s1)
	else
		set @minsir=len(@s2)
	set @i=1

	while @i<=@minsir
	begin
		set @c1=substring(@s1,@i,1)
		set @c2=substring(@s2,@i,1)
		set @n1=ascii(@c1)-(case when @c1<='9' then 48 else 55 end)
		set @n2=ascii(@c2)-(case when @c2<='9' then 48 else 55 end)
		if @tip='D'
		begin
			set @n=(@n1-@n2)%36
			if @n<0
				set @n=@n+36
		end
		else
			set @n=(@n1+@n2)%36
		set @n=@n%36
		set @n=(case when @n<10 then @n+48 else @n+55 end)
		set @raspuns=@raspuns+char(@n)
		set @i=@i+1
	end
	return @raspuns
	--print @raspuns
end
