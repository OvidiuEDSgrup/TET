--***
CREATE function f_areLMFiltru (@utilizator varchar(20)) returns int
as 
begin
return (case when exists (select 1
	from
		--proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'' and rtrim(@utilizator)<>''
		lmfiltrare l where l.utilizator=@utilizator
		) then 1 else 0 end)
end
