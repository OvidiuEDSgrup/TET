--***
create procedure calcul_cif @sub char(9), @numar char(20), @data datetime, 
	@total_cif_lei float output, @total_cif_valuta float output 
as 
begin
	set @total_cif_lei=(select isnull(sum(dbo.rot_val(pret_de_stoc,2)), 0) from pozdoc 
	where subunitate=@sub and tip='RQ' and numar=@numar and data=@data) 
	set @total_cif_valuta=(select isnull(sum(dbo.rot_val(pret_valuta,2)), 0) from pozdoc 
	where subunitate=@sub and tip='RQ' and numar=@numar and data=@data) 
end 
