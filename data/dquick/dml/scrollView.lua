function ScrollView(t)
	local scrollView = MouseArea {
	}

	for key, value in pairs(t) do
		print(value)
		scrollView[key] = value
	end
	return scrollView
end
