@description('Tags to be applied to resources')
@export()
#disable-next-line use-description-type-properties // This type does not have individual properties to describe
type tagsType = { *: string }
