--***
/**	functie temei legal	*/
Create
function  fTemei_legal (@Marca char(6))
returns varchar(50)
as
begin
declare @TemeiID varchar(3), @Temei_legal varchar(50)
select @Temei_legal=Val_inf from extinfop e where e.Marca=@Marca and e.cod_inf='RTEMEIINCET' and e.Val_inf<>''
if isnull(@Temei_legal,'')=''
Begin
	Set @TemeiID=isnull((select left(max(val_inf),2) from extinfop e where e.marca=@Marca and e.cod_inf='TEMEIINCET'),'')
	Set @Temei_legal=(case when @TemeiID='28' then 'art. 55 lit. b'   
		when @TemeiID='29' then 'art. 56 lit. a'   
		when @TemeiID='30' then 'art. 56 lit. b'  
		when @TemeiID='31' then 'art. 56 lit. d'  
		when @TemeiID='32' then 'art. 56 lit. e'  
		when @TemeiID='33' then 'art. 56 lit. f'  
		when @TemeiID='34' then 'art. 56 lit. g'  
		when @TemeiID='35' then 'art. 56 lit. h'  
		when @TemeiID='36' then 'art. 56 lit. i'  
		when @TemeiID='37' then 'art. 56 lit. j'  
		when @TemeiID='38' then 'art. 56 lit. k'  
		when @TemeiID='39' then 'art. 61 lit. a'  
		when @TemeiID='40' then 'art. 61 lit. b'  
		when @TemeiID='41' then 'art. 61 lit. c'  
		when @TemeiID='42' then 'art. 61 lit. d'  
		when @TemeiID='43' then 'art. 61 lit. e'  
		when @TemeiID='44' then 'art. 65 alin. 1'  
		when @TemeiID='45' then 'art. 65 alin. 1'  
		when @TemeiID='46' then 'art. 79 alin. 1'  
		when @TemeiID='47' then 'art. 31 alin. 4 indice 1'  
		when @TemeiID='48' then 'art. 31 alin. 4 indice 1'  
		when @TemeiID='49' then 'art. 79 alin. 7'  
		when @TemeiID='50' then 'art. 79 alin. 8' else '' end)  
End
return @Temei_legal
end
