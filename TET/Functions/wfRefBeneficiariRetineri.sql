--***
create function  wfRefBeneficiariRetineri (@Cod_beneficiar char(13)) returns int
as begin
	if exists (select 1 from resal where Cod_beneficiar=@Cod_beneficiar)
		return 1
	return 0
end
