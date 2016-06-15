create function [dbo].[fLitereMici]
(
@cod varchar(500)
)
returns varchar(500)
as
begin
	declare @i int , @char varchar(1)
	if @cod='' or @cod=' '
	goto sfarsit2
	set @i = 0
	while @i<LEN(@cod)
	begin
		set @i=@i+1
		select @char = SUBSTRING(@cod,@i,1)		
		/*verific daca caracterul parcurs este litera si daca este in intervalul 97  - 122 adica este Lower*/
		if isnumeric(@char) = 0 and ascii(@char) between 97 and 122 
			goto sfarsit1
		else if LEN(@cod)=@i
			goto sfarsit2
	end
sfarsit1: 
	return 1	
sfarsit2:	
	return 0
end
