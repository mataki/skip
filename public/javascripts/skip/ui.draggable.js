(function(jQuery) {

	//Make nodes selectable by expression
	jQuery.extend(jQuery.expr[':'], { draggable: "(' '+a.className+' ').indexOf(' ui-draggable ')" });


	//Macros for external methods that support chaining
	var methods = "destroy,enable,disable".split(",");
	for(var i=0;i<methods.length;i++) {
		var cur = methods[i], f;
		eval('f = function() { var a = arguments; return this.each(function() { if(jQuery(this).is(".ui-draggable")) jQuery.data(this, "ui-draggable")["'+cur+'"](a); }); }');
		jQuery.fn["draggable"+cur.substr(0,1).toUpperCase()+cur.substr(1)] = f;
	};
	
	//get instance method
	jQuery.fn.draggableInstance = function() {
		if(jQuery(this[0]).is(".ui-draggable")) return jQuery.data(this[0], "ui-draggable");
		return false;
	};

	jQuery.fn.draggable = function(o) {
		return this.each(function() {
			new jQuery.ui.draggable(this, o);
		});
	}
	
	jQuery.ui.ddmanager = {
		current: null,
		droppables: [],
		prepareOffsets: function(t, e) {
			var dropTop = jQuery.ui.ddmanager.dropTop = [];
			var dropLeft = jQuery.ui.ddmanager.dropLeft;
			var m = jQuery.ui.ddmanager.droppables;
			for (var i = 0; i < m.length; i++) {
				if(m[i].item.disabled) continue;
				m[i].offset = jQuery(m[i].item.element).offset();
				if (t && m[i].item.options.accept(t.element)) //Activate the droppable if used directly from draggables
					m[i].item.activate.call(m[i].item, e);
			}
		},
		fire: function(oDrag, e) {
			
			var oDrops = jQuery.ui.ddmanager.droppables;
			var oOvers = jQuery.grep(oDrops, function(oDrop) {
				
				if (!oDrop.item.disabled && jQuery.ui.intersect(oDrag, oDrop, oDrop.item.options.tolerance))
					oDrop.item.drop.call(oDrop.item, e);
			});
			jQuery.each(oDrops, function(i, oDrop) {
				if (!oDrop.item.disabled && oDrop.item.options.accept(oDrag.element)) {
					oDrop.out = 1; oDrop.over = 0;
					oDrop.item.deactivate.call(oDrop.item, e);
				}
			});
		},
		update: function(oDrag, e) {
			
			if(oDrag.options.refreshPositions) jQuery.ui.ddmanager.prepareOffsets();
			
			var oDrops = jQuery.ui.ddmanager.droppables;
			var oOvers = jQuery.grep(oDrops, function(oDrop) {
				if(oDrop.item.disabled) return false; 
				var isOver = jQuery.ui.intersect(oDrag, oDrop, oDrop.item.options.tolerance)
				if (!isOver && oDrop.over == 1) {
					oDrop.out = 1; oDrop.over = 0;
					oDrop.item.out.call(oDrop.item, e);
				}
				return isOver;
			});
			jQuery.each(oOvers, function(i, oOver) {
				if (oOver.over == 0) {
					oOver.out = 0; oOver.over = 1;
					oOver.item.over.call(oOver.item, e);
				}
			});
		}
	};
	
	jQuery.ui.draggable = function(el, o) {
		
		var options = {};
		jQuery.extend(options, o);
		var self = this;
		jQuery.extend(options, {
			_start: function(h, p, c, t, e) {
				self.start.apply(t, [self, e]); // Trigger the start callback				
			},
			_beforeStop: function(h, p, c, t, e) {
				self.stop.apply(t, [self, e]); // Trigger the start callback
			},
			_drag: function(h, p, c, t, e) {
				self.drag.apply(t, [self, e]); // Trigger the start callback
			},
			startCondition: function(e) {
				return !(e.target.className.indexOf("ui-resizable-handle") != -1 || self.disabled);	
			}			
		});
		
		jQuery.data(el, "ui-draggable", this);
		
		if (options.ghosting == true) options.helper = 'clone'; //legacy option check
		jQuery(el).addClass("ui-draggable");
		this.interaction = new jQuery.ui.mouseInteraction(el, options);
		
	}
	
	jQuery.extend(jQuery.ui.draggable.prototype, {
		plugins: {},
		currentTarget: null,
		lastTarget: null,
		destroy: function() {
			jQuery(this.interaction.element).removeClass("ui-draggable").removeClass("ui-draggable-disabled");
			this.interaction.destroy();
		},
		enable: function() {
			jQuery(this.interaction.element).removeClass("ui-draggable-disabled");
			this.disabled = false;
		},
		disable: function() {
			jQuery(this.interaction.element).addClass("ui-draggable-disabled");
			this.disabled = true;
		},
		prepareCallbackObj: function(self) {
			return {
				helper: self.helper,
				position: { left: self.pos[0], top: self.pos[1] },
				offset: self.options.cursorAt,
				draggable: self,
				options: self.options	
			}			
		},
		start: function(that, e) {
			
			var o = this.options;
			jQuery.ui.ddmanager.current = this;
			
			jQuery.ui.plugin.call(that, 'start', [e, that.prepareCallbackObj(this)]);
			jQuery(this.element).triggerHandler("dragstart", [e, that.prepareCallbackObj(this)], o.start);
			
			if (this.slowMode && jQuery.ui.droppable && !o.dropBehaviour)
				jQuery.ui.ddmanager.prepareOffsets(this, e);
			
			return false;
						
		},
		stop: function(that, e) {			
			
			var o = this.options;
			
			jQuery.ui.plugin.call(that, 'stop', [e, that.prepareCallbackObj(this)]);
			jQuery(this.element).triggerHandler("dragstop", [e, that.prepareCallbackObj(this)], o.stop);

			if (this.slowMode && jQuery.ui.droppable && !o.dropBehaviour) //If cursorAt is within the helper, we must use our drop manager
				jQuery.ui.ddmanager.fire(this, e);

			jQuery.ui.ddmanager.current = null;
			jQuery.ui.ddmanager.last = this;

			return false;
			
		},
		drag: function(that, e) {

			var o = this.options;

			jQuery.ui.ddmanager.update(this, e);

			this.pos = [this.pos[0]-o.cursorAt.left, this.pos[1]-o.cursorAt.top];

			jQuery.ui.plugin.call(that, 'drag', [e, that.prepareCallbackObj(this)]);
			var nv = jQuery(this.element).triggerHandler("drag", [e, that.prepareCallbackObj(this)], o.drag);

			var nl = (nv && nv.left) ? nv.left : this.pos[0];
			var nt = (nv && nv.top) ? nv.top : this.pos[1];
			
			jQuery(this.helper).css('left', nl+'px').css('top', nt+'px'); // Stick the helper to the cursor
			return false;
			
		}
	});

})(jQuery);
